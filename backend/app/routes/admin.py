from fastapi import APIRouter, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.deps import AdminUser, DbSession
from app.models import (
    DeliveryLocation,
    SellerProfile,
    SellerRequest,
    SellerRequestStatus,
    User,
    UserRole,
)
from app.schemas import DeliveryLocationApproveIn, SellerApproveIn, SellerRequestOut

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/seller-requests", response_model=list[SellerRequestOut])
def list_seller_requests(db: DbSession, _: AdminUser):
    q = (
        select(SellerRequest)
        .options(joinedload(SellerRequest.user))
        .where(SellerRequest.status == SellerRequestStatus.pending)
        .order_by(SellerRequest.id.desc())
    )
    return db.scalars(q).unique().all()


@router.post("/seller-approve")
def approve_seller(body: SellerApproveIn, db: DbSession, _: AdminUser):
    user = db.get(User, body.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    profile = user.seller_profile
    if not profile:
        raise HTTPException(status_code=400, detail="User has no seller profile")

    req = db.scalar(select(SellerRequest).where(SellerRequest.user_id == user.id))
    if body.approve:
        profile.approved = True
        user.role = UserRole.seller
        user.is_verified_seller = True
        if req:
            req.status = SellerRequestStatus.approved
    else:
        if req:
            req.status = SellerRequestStatus.rejected
    db.commit()
    return {"ok": True, "user_id": user.id, "approved": body.approve}


@router.post("/delivery-location-approve")
def approve_delivery_location(body: DeliveryLocationApproveIn, db: DbSession, _: AdminUser):
    loc = db.get(DeliveryLocation, body.location_id)
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")
    loc.is_approved = bool(body.approve)
    db.commit()
    return {"ok": True, "location_id": loc.id, "is_approved": loc.is_approved}


@router.get("/delivery-locations/pending")
def pending_locations(db: DbSession, _: AdminUser):
    q = select(DeliveryLocation).where(DeliveryLocation.is_approved.is_(False))
    locs = db.scalars(q).all()
    return [
        {
            "id": l.id,
            "seller_id": l.seller_id,
            "name": l.name,
            "latitude": l.latitude,
            "longitude": l.longitude,
        }
        for l in locs
    ]
