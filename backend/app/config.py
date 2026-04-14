from functools import lru_cache
from typing import Optional

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    DATABASE_URL: Optional[str] = None
    SECRET_KEY: str = "change-me-in-production-use-openssl-rand-hex-32"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    CORS_ORIGINS: str = "http://localhost:3000,http://127.0.0.1:3000,http://localhost:5173,http://127.0.0.1:5173"
    SEED_ADMIN_EMAIL: Optional[str] = None
    SEED_ADMIN_PASSWORD: Optional[str] = None
    SEED_ADMIN_NAME: str = "System Admin"
    SEED_DEMO_DATA: bool = False
    DEMO_UNIVERSITY: str = "Demo Campus"
    DEMO_DEFAULT_PASSWORD: str = "Demo@12345"

    @field_validator("DATABASE_URL")
    @classmethod
    def normalize_database_url(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        trimmed = value.strip()
        return trimmed or None

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
