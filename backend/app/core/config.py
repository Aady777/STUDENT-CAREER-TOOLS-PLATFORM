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
    # Development:  CORS_ORIGINS=["*"]
    # Production:   CORS_ORIGINS=["https://yourdomain.com"]
    CORS_ORIGINS: list[str] = ["*"]

    # ── Rate Limiting ────────────────────────────────────
    # Fine-tune via environment variables for production hardening
    RATE_LIMIT_LOGIN_MAX: int = 5       # requests per window
    RATE_LIMIT_LOGIN_WINDOW: int = 60   # seconds
    RATE_LIMIT_REGISTER_MAX: int = 3
    RATE_LIMIT_REGISTER_WINDOW: int = 60
    RATE_LIMIT_SUBMIT_MAX: int = 10
    RATE_LIMIT_SUBMIT_WINDOW: int = 60

    # ── SMTP / Email Notifications ───────────────────────
    # Set NOTIFICATIONS_ENABLED=True and fill SMTP_* to activate real emails.
    NOTIFICATIONS_ENABLED: bool = False
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM: str = "noreply@student-utility.app"

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


@lru_cache()
def get_settings() -> Settings:
    return Settings()
