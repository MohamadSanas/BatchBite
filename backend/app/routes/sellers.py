from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.models import SellerProfile, User

router = APIRouter(prefix="/sellers", tags=["Sellers"])


class SellerListOut(BaseModel):
    seller_id: int
    user_id: int
    kitchen_name: str
    description: str | None
    university: str


@router.get("", response_model=list[SellerListOut])
def list_sellers(university: Optional[str] = Query(default=None), db: Session = Depends(get_db)):
    q = select(SellerProfile, User).join(User, SellerProfile.user_id == User.id).where(SellerProfile.approved.is_(True))
    if university and university.strip():
        q = q.where(User.university == university.strip())
    q = q.order_by(User.university.asc(), SellerProfile.kitchen_name.asc())
    rows = db.execute(q).all()
    return [
        SellerListOut(
            seller_id=sp.id,
            user_id=u.id,
            kitchen_name=sp.kitchen_name,
            description=sp.description,
            university=u.university,
        )
        for sp, u in rows
    ]
