from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import SellerProfile, SellerRequest, SellerRequestStatus, User, UserRole
from app.schemas import KitchenUpdateIn, SellerRequestIn

router = APIRouter(prefix="/seller", tags=["Seller"])


@router.post("/request", status_code=status.HTTP_201_CREATED)
def create_seller_request(
    body: SellerRequestIn,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    if user.role == UserRole.admin:
        raise HTTPException(status_code=400, detail="Admins cannot request seller access")
    existing = db.scalar(select(SellerRequest).where(SellerRequest.user_id == user.id))
    if existing and existing.status == SellerRequestStatus.pending:
        raise HTTPException(status_code=400, detail="You already have a pending request")
    profile = user.seller_profile
    if profile and profile.approved:
        raise HTTPException(status_code=400, detail="You are already an approved seller")

    req = SellerRequest(user_id=user.id, status=SellerRequestStatus.pending)
    db.add(req)
    if profile is None:
        profile = SellerProfile(
            user_id=user.id,
            kitchen_name=body.kitchen_name,
            description=body.description,
            approved=False,
        )
        db.add(profile)
    else:
        profile.kitchen_name = body.kitchen_name
        profile.description = body.description
    db.commit()
    db.refresh(req)
    return {"id": req.id, "status": req.status.value}


@router.patch("/profile")
def update_kitchen(
    body: KitchenUpdateIn,
    db: Session = Depends(get_db),
    user: Annotated[User, Depends(get_current_user)] = ...,
):
    if user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Seller access required")
    profile = user.seller_profile
    if not profile or not profile.approved:
        raise HTTPException(status_code=403, detail="Approved seller profile required")
    if body.kitchen_name is not None:
        profile.kitchen_name = body.kitchen_name
    if body.description is not None:
        profile.description = body.description
    db.commit()
    db.refresh(profile)
    return {"kitchen_name": profile.kitchen_name, "description": profile.description}
