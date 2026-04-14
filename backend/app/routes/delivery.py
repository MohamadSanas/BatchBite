from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import OptionalUser, get_current_user
from app.models import DeliveryLocation, SellerProfile, User, UserRole
from app.schemas import DeliveryLocationIn, DeliveryLocationOut

router = APIRouter(tags=["Delivery"])


def _seller_profile_or_403(user: User, db: Session) -> SellerProfile:
    if user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Seller access required")
    profile = user.seller_profile
    if not profile or not profile.approved:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Approved seller profile required")
    return profile


@router.post("/delivery-location", response_model=DeliveryLocationOut)
def create_delivery_location(
    body: DeliveryLocationIn,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    sp = _seller_profile_or_403(user, db)
    loc = DeliveryLocation(
        seller_id=sp.id,
        name=body.name,
        latitude=body.latitude,
        longitude=body.longitude,
        is_approved=False,
    )
    db.add(loc)
    db.commit()
    db.refresh(loc)
    return loc


@router.get("/delivery-location/{seller_id}", response_model=list[DeliveryLocationOut])
def list_delivery_for_seller(
    seller_id: int,
    db: Session = Depends(get_db),
    approved_only: bool = True,
    user: OptionalUser = None,
):
    sp = db.get(SellerProfile, seller_id)
    if not sp or not sp.approved:
        raise HTTPException(status_code=404, detail="Seller not found")
    q = select(DeliveryLocation).where(DeliveryLocation.seller_id == seller_id)
    owner = bool(user and user.seller_profile and user.seller_profile.id == seller_id)
    if approved_only:
        q = q.where(DeliveryLocation.is_approved.is_(True))
    elif not owner:
        raise HTTPException(status_code=403, detail="Not allowed to view pending locations")
    q = q.order_by(DeliveryLocation.id)
    return db.scalars(q).all()
