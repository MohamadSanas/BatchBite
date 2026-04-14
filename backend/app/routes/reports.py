from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.database import get_db
from app.deps import AdminUser, get_current_user
from app.models import Order, OrderItem, SellerProfile, Transaction, User, UserRole
from app.services.pdf_reports import build_order_summary_pdf, build_sales_report_pdf

router = APIRouter(prefix="/reports", tags=["Reports"])


@router.get("/pdf/order/{order_id}")
def pdf_order_summary(
    order_id: int,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    o = db.scalar(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.food_item),
            selectinload(Order.delivery_location),
        )
        .where(Order.id == order_id)
    )
    if not o:
        raise HTTPException(status_code=404, detail="Order not found")
    profile = user.seller_profile
    if user.role != UserRole.admin and o.buyer_id != user.id and (not profile or profile.id != o.seller_id):
        raise HTTPException(status_code=403, detail="Not allowed")
    data = build_order_summary_pdf(o)
    return Response(
        content=data,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="order-{order_id}.pdf"'},
    )


def _seller_for_reports(user: User, db: Session) -> SellerProfile:
    if user.role == UserRole.admin:
        raise HTTPException(status_code=400, detail="Use seller account for sales PDFs")
    profile = user.seller_profile
    if not profile or not profile.approved:
        raise HTTPException(status_code=403, detail="Seller access required")
    return profile


@router.get("/pdf/daily")
def pdf_daily_sales(
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    sp = _seller_for_reports(user, db)
    start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    end = start + timedelta(days=1)
    return _sales_pdf_response(db, sp.id, start, end, "daily")


@router.get("/pdf/monthly")
def pdf_monthly_profit(
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    sp = _seller_for_reports(user, db)
    now = datetime.now(timezone.utc)
    start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    if now.month == 12:
        end = start.replace(year=start.year + 1, month=1)
    else:
        end = start.replace(month=start.month + 1)
    return _sales_pdf_response(db, sp.id, start, end, "monthly")


def _sales_pdf_response(db: Session, seller_id: int, start: datetime, end: datetime, label: str):
    q = select(Transaction).where(
        Transaction.seller_id == seller_id,
        Transaction.created_at >= start,
        Transaction.created_at < end,
    )
    rows = db.scalars(q).all()
    total = sum(t.total_amount for t in rows)
    profit = sum(t.profit for t in rows)
    detail_rows = [(f"Txn #{t.id} @ {t.created_at.isoformat()}", t.total_amount) for t in rows]
    pdf = build_sales_report_pdf(
        title=f"{label.capitalize()} sales — seller {seller_id}",
        rows=detail_rows,
        totals={"total": total, "profit": profit},
    )
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="sales-{label}-{seller_id}.pdf"'},
    )


@router.get("/admin/summary")
def admin_transactions_summary(_: AdminUser, db: Session = Depends(get_db)):
    total = db.scalar(select(func.coalesce(func.sum(Transaction.total_amount), 0.0))) or 0.0
    profit = db.scalar(select(func.coalesce(func.sum(Transaction.profit), 0.0))) or 0.0
    count = db.scalar(select(func.count(Transaction.id))) or 0
    return {"transaction_count": int(count), "total_amount": float(total), "profit": float(profit)}
