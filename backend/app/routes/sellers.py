from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

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
def list_sellers(university: str = Query(..., min_length=1), db: Session = Depends(get_db)):
    q = (
        select(SellerProfile, User)
        .join(User, SellerProfile.user_id == User.id)
        .where(User.university == university, SellerProfile.approved.is_(True))
    )
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
