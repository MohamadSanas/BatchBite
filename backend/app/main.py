import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.config import get_settings
from app.database import Base, SessionLocal, engine
from app.models import User, UserRole
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


def initialize_database() -> None:
    Base.metadata.create_all(bind=engine)
    seed_admin()
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
