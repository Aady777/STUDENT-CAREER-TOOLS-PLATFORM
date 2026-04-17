"""
Database engine, session factory, and declarative base.
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import get_settings

settings = get_settings()

# ── Engine ───────────────────────────────────────────────
engine = create_engine(
    settings.DATABASE_URL,
    connect_args=(
        {"check_same_thread": False}
        if settings.DATABASE_URL.startswith("sqlite")
        else {}
    ),
    echo=settings.DEBUG,
)

# ── Session ──────────────────────────────────────────────
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# ── Base ─────────────────────────────────────────────────
Base = declarative_base()
