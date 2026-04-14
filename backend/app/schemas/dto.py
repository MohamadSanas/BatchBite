from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.models import OrderStatus, SellerRequestStatus, UserRole


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RegisterIn(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    university: str = Field(min_length=1, max_length=255)

    @field_validator("password")
    @classmethod
    def bcrypt_limit(cls, v: str) -> str:
        if len(v.encode("utf-8")) > 72:
            raise ValueError("Password too long for bcrypt")
        return v


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: int
    name: str
    email: str
    university: str
    role: UserRole
    is_verified_seller: bool

    model_config = {"from_attributes": True}


class SellerRequestIn(BaseModel):
    kitchen_name: str = Field(min_length=1, max_length=255)
    description: Optional[str] = None


class KitchenUpdateIn(BaseModel):
    kitchen_name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    description: Optional[str] = None


class SellerApproveIn(BaseModel):
    user_id: int
    approve: bool = True


class SellerRequestOut(BaseModel):
    id: int
    user_id: int
    status: SellerRequestStatus
    user: UserOut

    model_config = {"from_attributes": True}


class FoodItemIn(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    price: float = Field(gt=0)
    available: bool = True


class FoodItemOut(BaseModel):
    id: int
    seller_id: int
    name: str
    price: float
    available: bool

    model_config = {"from_attributes": True}


class DeliveryLocationIn(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class DeliveryLocationOut(BaseModel):
    id: int
    seller_id: int
    name: str
    latitude: Optional[float]
    longitude: Optional[float]
    is_approved: bool

    model_config = {"from_attributes": True}


class DeliveryLocationApproveIn(BaseModel):
    location_id: int
    approve: bool = True


class OrderItemIn(BaseModel):
    food_item_id: int
    quantity: int = Field(ge=1)


class OrderCreateIn(BaseModel):
    seller_id: int
    delivery_location_id: int
    deadline_time: datetime
    items: list[OrderItemIn] = Field(min_length=1)


class OrderItemOut(BaseModel):
    id: int
    food_item_id: int
    quantity: int
    food_name: Optional[str] = None
    unit_price: Optional[float] = None

    model_config = {"from_attributes": True}


class OrderOut(BaseModel):
    id: int
    buyer_id: int
    seller_id: int
    status: OrderStatus
    delivery_location_id: int
    delivery_location_name: Optional[str] = None
    deadline_time: datetime
    created_at: datetime
    cancellation_reason: Optional[str] = None
    items: list[OrderItemOut] = Field(default_factory=list)
    kitchen_name: Optional[str] = None

    model_config = {"from_attributes": True}


class OrderStatusUpdateIn(BaseModel):
    status: OrderStatus
    reason: Optional[str] = None


class OrderCancelIn(BaseModel):
    reason: Optional[str] = None


class SummaryFoodTotal(BaseModel):
    food_item_id: int
    food_name: str
    total_quantity: int


class SummaryLocationGroup(BaseModel):
    delivery_location_id: int
    delivery_location_name: str
    items: list[SummaryFoodTotal]


class OrdersSummaryOut(BaseModel):
    groups: list[SummaryLocationGroup]


class ReportRangeIn(BaseModel):
    start: Optional[datetime] = None
    end: Optional[datetime] = None
