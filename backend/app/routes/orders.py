from collections import defaultdict
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.deps import get_current_user
from app.models import (
    DeliveryLocation,
    FoodItem,
    Order,
    OrderItem,
    OrderStatus,
    SellerProfile,
    Transaction,
    User,
    UserRole,
)
from app.schemas import OrderCancelIn, OrderCreateIn, OrderItemOut, OrdersSummaryOut, OrderOut, OrderStatusUpdateIn

router = APIRouter(tags=["Orders"])


def _now():
    return datetime.now(timezone.utc)


def _order_to_out(order: Order) -> OrderOut:
    items_out = []
    for oi in order.items:
        fi = oi.food_item
        items_out.append(
            OrderItemOut(
                id=oi.id,
                food_item_id=oi.food_item_id,
                quantity=oi.quantity,
                food_name=fi.name if fi else None,
                unit_price=fi.price if fi else None,
            )
        )
    loc_name = order.delivery_location.name if order.delivery_location else None
    kitchen = order.seller.kitchen_name if order.seller else None
    return OrderOut(
        id=order.id,
        buyer_id=order.buyer_id,
        seller_id=order.seller_id,
        status=order.status,
        delivery_location_id=order.delivery_location_id,
        delivery_location_name=loc_name,
        deadline_time=order.deadline_time,
        created_at=order.created_at,
        cancellation_reason=order.cancellation_reason,
        items=items_out,
        kitchen_name=kitchen,
    )


@router.post("/orders", response_model=OrderOut)
def create_order(
    body: OrderCreateIn,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    if _now() > body.deadline_time:
        raise HTTPException(status_code=400, detail="Order deadline has passed")

    seller = db.get(SellerProfile, body.seller_id)
    if not seller or not seller.approved:
        raise HTTPException(status_code=404, detail="Seller not found")

    loc = db.get(DeliveryLocation, body.delivery_location_id)
    if not loc or loc.seller_id != seller.id:
        raise HTTPException(status_code=400, detail="Invalid delivery location")
    if not loc.is_approved:
        raise HTTPException(status_code=400, detail="Delivery location is not approved yet")

    owner = db.get(User, seller.user_id)
    if owner and owner.university != user.university:
        raise HTTPException(status_code=400, detail="Seller is not on your campus")

    order = Order(
        buyer_id=user.id,
        seller_id=seller.id,
        status=OrderStatus.confirmed,
        delivery_location_id=loc.id,
        deadline_time=body.deadline_time,
    )
    db.add(order)
    db.flush()

    for line in body.items:
        fi = db.get(FoodItem, line.food_item_id)
        if not fi or fi.seller_id != seller.id:
            raise HTTPException(status_code=400, detail=f"Invalid food item {line.food_item_id}")
        if not fi.available:
            raise HTTPException(status_code=400, detail=f"Item not available: {fi.name}")
        db.add(OrderItem(order_id=order.id, food_item_id=fi.id, quantity=line.quantity))

    db.commit()
    db.refresh(order)
    order = db.scalar(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
            selectinload(Order.seller),
        )
        .where(Order.id == order.id)
    )
    return _order_to_out(order)


@router.get("/orders", response_model=list[OrderOut])
def list_buyer_orders(db: Session = Depends(get_db), user: Annotated[User, Depends(get_current_user)] = ...):
    q = (
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
            selectinload(Order.seller),
        )
        .where(Order.buyer_id == user.id)
        .order_by(Order.id.desc())
    )
    orders = db.scalars(q).unique().all()
    return [_order_to_out(o) for o in orders]


@router.get("/seller/orders", response_model=list[OrderOut])
def list_seller_orders(db: Session = Depends(get_db), user: Annotated[User, Depends(get_current_user)] = ...):
    if user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Seller access required")
    profile = user.seller_profile
    if not profile or not profile.approved:
        raise HTTPException(status_code=403, detail="Approved seller profile required")
    q = (
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
            selectinload(Order.seller),
        )
        .where(Order.seller_id == profile.id)
        .order_by(Order.id.desc())
    )
    orders = db.scalars(q).unique().all()
    return [_order_to_out(o) for o in orders]


@router.get("/orders/summary", response_model=OrdersSummaryOut)
def orders_summary(db: Session = Depends(get_db), user: Annotated[User, Depends(get_current_user)] = ...):
    if user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Seller access required")
    profile = user.seller_profile
    if not profile or not profile.approved:
        raise HTTPException(status_code=403, detail="Approved seller profile required")

    q = (
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
        )
        .where(
            Order.seller_id == profile.id,
            Order.status.notin_([OrderStatus.delivered, OrderStatus.cancelled]),
        )
    )
    orders = db.scalars(q).unique().all()

    grouped: dict[int, dict] = defaultdict(lambda: {"name": "", "items": defaultdict(int)})
    for o in orders:
        lid = o.delivery_location_id
        grouped[lid]["name"] = o.delivery_location.name if o.delivery_location else ""
        for oi in o.items:
            fid = oi.food_item_id
            grouped[lid]["items"][fid] += oi.quantity

    food_names = {fi.id: fi.name for fi in db.scalars(select(FoodItem).where(FoodItem.seller_id == profile.id)).all()}

    from app.schemas import SummaryFoodTotal, SummaryLocationGroup

    groups = []
    for lid, data in grouped.items():
        items = [
            SummaryFoodTotal(food_item_id=fid, food_name=food_names.get(fid, str(fid)), total_quantity=qty)
            for fid, qty in data["items"].items()
        ]
        items.sort(key=lambda x: x.food_name)
        groups.append(
            SummaryLocationGroup(
                delivery_location_id=lid,
                delivery_location_name=data["name"],
                items=items,
            )
        )
    groups.sort(key=lambda g: g.delivery_location_name)
    return OrdersSummaryOut(groups=groups)


@router.get("/orders/{order_id}", response_model=OrderOut)
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    o = db.scalar(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
            selectinload(Order.seller),
        )
        .where(Order.id == order_id)
    )
    if not o:
        raise HTTPException(status_code=404, detail="Order not found")
    if user.role == UserRole.admin:
        return _order_to_out(o)
    profile = user.seller_profile
    if o.buyer_id == user.id or (profile and profile.id == o.seller_id):
        return _order_to_out(o)
    raise HTTPException(status_code=403, detail="Not allowed")


@router.patch("/orders/{order_id}/status", response_model=OrderOut)
def update_order_status(
    order_id: int,
    body: OrderStatusUpdateIn,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    if user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Seller access required")
    profile = user.seller_profile
    if not profile or not profile.approved:
        raise HTTPException(status_code=403, detail="Approved seller profile required")

    o = db.get(Order, order_id)
    if not o or o.seller_id != profile.id:
        raise HTTPException(status_code=404, detail="Order not found")

    new_status = body.status
    allowed = {OrderStatus.preparing, OrderStatus.ready, OrderStatus.cancelled}
    if new_status not in allowed:
        raise HTTPException(status_code=400, detail="Invalid status transition for seller")

    if o.status in (OrderStatus.delivered, OrderStatus.cancelled):
        raise HTTPException(status_code=400, detail="Order is finalized")

    if new_status == OrderStatus.cancelled:
        o.cancellation_reason = body.reason or "Cancelled by seller"
    o.status = new_status
    if new_status == OrderStatus.ready:
        o.ready_notified_at = _now()
    db.commit()

    o = db.scalar(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
            selectinload(Order.seller),
        )
        .where(Order.id == order_id)
    )
    return _order_to_out(o)


@router.post("/orders/{order_id}/confirm-delivery", response_model=OrderOut)
def confirm_delivery(
    order_id: int,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    o = db.scalar(
        select(Order)
        .options(selectinload(Order.items).selectinload(OrderItem.food_item))
        .where(Order.id == order_id)
    )
    if not o or o.buyer_id != user.id:
        raise HTTPException(status_code=404, detail="Order not found")
    if o.status != OrderStatus.ready:
        raise HTTPException(status_code=400, detail="Order is not ready for pickup confirmation")

    total = 0.0
    for oi in o.items:
        total += oi.food_item.price * oi.quantity

    o.status = OrderStatus.delivered
    db.add(
        Transaction(
            seller_id=o.seller_id,
            total_amount=total,
            profit=total,
            order_id=o.id,
        )
    )
    db.commit()

    o = db.scalar(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
            selectinload(Order.seller),
        )
        .where(Order.id == order_id)
    )
    return _order_to_out(o)


@router.post("/orders/{order_id}/cancel", response_model=OrderOut)
def cancel_order(
    order_id: int,
    body: OrderCancelIn,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    o = db.get(Order, order_id)
    if not o:
        raise HTTPException(status_code=404, detail="Order not found")

    profile = user.seller_profile
    is_seller = profile and profile.id == o.seller_id and user.role in (UserRole.seller, UserRole.admin)
    is_buyer = o.buyer_id == user.id

    if not is_seller and not is_buyer:
        raise HTTPException(status_code=403, detail="Not allowed")

    if o.status in (OrderStatus.delivered, OrderStatus.cancelled):
        raise HTTPException(status_code=400, detail="Order cannot be cancelled")

    if is_buyer:
        if _now() > o.deadline_time:
            raise HTTPException(status_code=400, detail="Cannot cancel after deadline")
        o.cancellation_reason = body.reason or "Cancelled by buyer"
    else:
        if not body.reason:
            raise HTTPException(status_code=400, detail="Seller cancellation requires a reason")
        o.cancellation_reason = body.reason

    o.status = OrderStatus.cancelled
    db.commit()

    o = db.scalar(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
            selectinload(Order.seller),
        )
        .where(Order.id == order_id)
    )
    return _order_to_out(o)
