from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import FoodItem, SellerProfile, User, UserRole
from app.schemas import FoodItemIn, FoodItemOut

router = APIRouter(tags=["Food"])


def _seller_profile_or_403(user: User, db: Session) -> SellerProfile:
    if user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Seller access required")
    profile = user.seller_profile
    if not profile or not profile.approved:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Approved seller profile required")
    return profile


@router.post("/food", response_model=FoodItemOut)
def create_food(
    body: FoodItemIn,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    sp = _seller_profile_or_403(user, db)
    item = FoodItem(seller_id=sp.id, name=body.name, price=body.price, available=body.available)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/food/{seller_id}", response_model=list[FoodItemOut])
def list_food_for_seller(seller_id: int, db: Session = Depends(get_db)):
    sp = db.get(SellerProfile, seller_id)
    if not sp or not sp.approved:
        raise HTTPException(status_code=404, detail="Seller not found")
    q = select(FoodItem).where(FoodItem.seller_id == seller_id).order_by(FoodItem.id)
    return db.scalars(q).all()
