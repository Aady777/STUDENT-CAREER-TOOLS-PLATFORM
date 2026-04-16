"""
Application configuration using Pydantic Settings.
Loads values from environment variables / .env file.
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── App ──────────────────────────────────────────────
    APP_NAME: str = "Student Utility API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # ── Database ─────────────────────────────────────────
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/student_db"

    # ── PostgreSQL Connection Pool (Production Tuning) ───
    DB_POOL_SIZE: int = 10          # number of persistent connections
    DB_MAX_OVERFLOW: int = 20       # extra connections allowed above pool_size
    DB_POOL_TIMEOUT: int = 30       # seconds to wait before giving up
    DB_POOL_RECYCLE: int = 1800     # recycle connections every 30 min
    DB_POOL_PRE_PING: bool = True   # test connection health before each use

    # ── Redis ────────────────────────────────────────────
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    REDIS_PASSWORD: str | None = None

    # ── JWT / Auth ───────────────────────────────────────
    SECRET_KEY: str = "super-secret-change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

    # ── CORS ─────────────────────────────────────────────
    CORS_ORIGINS: list[str] = ["*"]

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


@lru_cache()
def get_settings() -> Settings:
    return Settings()
