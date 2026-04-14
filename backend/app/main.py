import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import inspect, select, text

from app.config import get_settings
from app.database import Base, SessionLocal, engine
from app.models import DeliveryLocation, FoodItem, SellerProfile, User, UserRole
from app.core.security import hash_password
from app.routes import admin, auth, delivery, food, orders, reports, seller, sellers

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()

def seed_admin():
    if not settings.SEED_ADMIN_EMAIL or not settings.SEED_ADMIN_PASSWORD:
        return
    with SessionLocal() as db:
        exists = db.scalar(select(User).where(User.email == settings.SEED_ADMIN_EMAIL.lower()))
        if exists:
            return
        admin_user = User(
            name=settings.SEED_ADMIN_NAME,
            email=settings.SEED_ADMIN_EMAIL.lower(),
            password_hash=hash_password(settings.SEED_ADMIN_PASSWORD),
            university="System",
            role=UserRole.admin,
            is_verified_seller=False,
        )
        db.add(admin_user)
        db.commit()
        logger.info("Seeded admin user %s", admin_user.email)


def ensure_schema_compatibility() -> None:
    # Lightweight compatibility patch for existing databases without food image column.
    inspector = inspect(engine)
    if "food_items" not in inspector.get_table_names():
        return
    columns = {col["name"] for col in inspector.get_columns("food_items")}
    if "image_url" in columns:
        return
    with engine.begin() as conn:
        conn.execute(text("ALTER TABLE food_items ADD COLUMN image_url VARCHAR(1024)"))
    logger.info("Added missing column food_items.image_url")


def seed_demo_data() -> None:
    if not settings.SEED_DEMO_DATA:
        return

    demo_password_hash = hash_password(settings.DEMO_DEFAULT_PASSWORD)
    university = settings.DEMO_UNIVERSITY

    demo_users = [
        {"name": "Demo Admin", "email": "admin@batchbite.demo", "role": UserRole.admin, "seller": False},
        {"name": "Aisha Kitchen", "email": "seller1@batchbite.demo", "role": UserRole.seller, "seller": True},
        {"name": "Ravi Tiffins", "email": "seller2@batchbite.demo", "role": UserRole.seller, "seller": True},
        {"name": "Nila Buyer", "email": "buyer1@batchbite.demo", "role": UserRole.buyer, "seller": False},
        {"name": "Arun Buyer", "email": "buyer2@batchbite.demo", "role": UserRole.buyer, "seller": False},
    ]

    with SessionLocal() as db:
        created_any = False
        seller_profiles: list[SellerProfile] = []

        for d in demo_users:
            user = db.scalar(select(User).where(User.email == d["email"]))
            if not user:
                user = User(
                    name=d["name"],
                    email=d["email"],
                    password_hash=demo_password_hash,
                    university=university if d["role"] != UserRole.admin else "System",
                    role=d["role"],
                    is_verified_seller=bool(d["seller"]),
                )
                db.add(user)
                db.flush()
                created_any = True
            if d["seller"]:
                profile = db.scalar(select(SellerProfile).where(SellerProfile.user_id == user.id))
                if not profile:
                    profile = SellerProfile(
                        user_id=user.id,
                        kitchen_name=f"{d['name']} Kitchen",
                        description=f"Popular meals from {d['name']}.",
                        approved=True,
                    )
                    db.add(profile)
                    db.flush()
                    created_any = True
                seller_profiles.append(profile)

                loc = db.scalar(select(DeliveryLocation).where(DeliveryLocation.seller_id == profile.id))
                if not loc:
                    db.add(
                        DeliveryLocation(
                            seller_id=profile.id,
                            name=f"{university} Main Gate",
                            latitude=None,
                            longitude=None,
                            is_approved=True,
                        )
                    )
                    created_any = True

        sample_foods = [
            ("Chicken Biryani", 149.0, "https://images.unsplash.com/photo-1563379091339-03246963d25b"),
            ("Paneer Wrap", 89.0, "https://images.unsplash.com/photo-1512621776951-a57141f2eefd"),
            ("Veg Fried Rice", 99.0, "https://images.unsplash.com/photo-1512058564366-18510be2db19"),
        ]
        for profile in seller_profiles:
            for name, price, image_url in sample_foods:
                exists = db.scalar(
                    select(FoodItem).where(FoodItem.seller_id == profile.id, FoodItem.name == name)
                )
                if not exists:
                    db.add(
                        FoodItem(
                            seller_id=profile.id,
                            name=name,
                            price=price,
                            image_url=image_url,
                            available=True,
                        )
                    )
                    created_any = True

        if created_any:
            db.commit()
            logger.info("Seeded demo users, sellers, buyers, and food items")
        else:
            db.rollback()
            logger.info("Demo seed skipped (already populated)")


def initialize_database() -> None:
    Base.metadata.create_all(bind=engine)
    ensure_schema_compatibility()
    seed_admin()
    seed_demo_data()
    logger.info("Database ready (PostgreSQL if DATABASE_URL set, else SQLite)")


@asynccontextmanager
async def lifespan(_: FastAPI):
    initialize_database()
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title="Campus Multi-Vendor Food Delivery System",
        description="Batch campus food orders with JWT auth, seller approval, and PDF reports.",
        version="1.0.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list or ["*"],
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth.router)
    app.include_router(seller.router)
    app.include_router(admin.router)
    app.include_router(sellers.router)
    app.include_router(food.router)
    app.include_router(delivery.router)
    app.include_router(orders.router)
    app.include_router(reports.router)

    @app.get("/health")
    def health():
        return {"status": "ok", "service": "campus-food-backend"}

    return app


app = create_app()
