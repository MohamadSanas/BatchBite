from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from sqlalchemy.pool import NullPool

from app.config import get_settings

settings = get_settings()

if settings.DATABASE_URL:
    database_url = settings.DATABASE_URL.strip()
    connect_args = {}
    engine_kwargs = {"pool_pre_ping": True}

    # Supabase/Postgres should always use TLS in hosted environments.
    if database_url.startswith(("postgresql://", "postgresql+")) and "sslmode=" not in database_url:
        separator = "&" if "?" in database_url else "?"
        database_url = f"{database_url}{separator}sslmode=require"

    # Pooler endpoints (session/transaction) work best with client-side pooling disabled.
    if ".pooler.supabase.com" in database_url:
        engine_kwargs["poolclass"] = NullPool
else:
    database_url = "sqlite:///./campus_food.db"
    connect_args = {"check_same_thread": False}
    engine_kwargs = {}

engine = create_engine(database_url, connect_args=connect_args, **engine_kwargs)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
