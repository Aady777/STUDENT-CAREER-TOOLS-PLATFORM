"""
Database engine, session factory, and declarative base.

PostgreSQL-optimised with:
- QueuePool (default for PostgreSQL) with tuned pool_size / max_overflow
- pool_pre_ping  → auto-drops stale connections (handles DB restarts)
- pool_recycle   → prevents connections from growing stale over time
- Contextmanager helper `db_session` for use outside of FastAPI DI
"""

import logging
from contextlib import contextmanager
from typing import Generator

from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import sessionmaker, declarative_base, Session

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


# ── Engine ───────────────────────────────────────────────
engine = create_engine(
    settings.DATABASE_URL,
    # ── Connection Pool Tuning ────────────────────────────
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_timeout=settings.DB_POOL_TIMEOUT,
    pool_recycle=settings.DB_POOL_RECYCLE,
    pool_pre_ping=settings.DB_POOL_PRE_PING,   # sends SELECT 1 before reuse
    # ── Logging ──────────────────────────────────────────
    echo=settings.DEBUG,
)


# ── Pool event listeners ──────────────────────────────────
@event.listens_for(engine, "connect")
def on_connect(dbapi_connection, connection_record):
    """Log whenever a brand-new physical connection is created."""
    logger.debug("New DB connection created: %s", connection_record)


@event.listens_for(engine, "checkout")
def on_checkout(dbapi_connection, connection_record, connection_proxy):
    """Log whenever a connection is checked out from the pool."""
    logger.debug("DB connection checked out from pool.")


@event.listens_for(engine, "checkin")
def on_checkin(dbapi_connection, connection_record):
    """Log whenever a connection is returned to the pool."""
    logger.debug("DB connection returned to pool.")


# ── Session factory ──────────────────────────────────────
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    expire_on_commit=False,   # prevent DetachedInstanceError after commit
)


# ── Declarative Base ─────────────────────────────────────
Base = declarative_base()


# ── FastAPI DI helper ────────────────────────────────────
def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency – yields a DB session and guarantees cleanup.
    Usage:
        db: Session = Depends(get_db)
    """
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


# ── Context manager helper (scripts / workers) ───────────
@contextmanager
def db_session() -> Generator[Session, None, None]:
    """
    Use outside of FastAPI (e.g. background tasks, CLI scripts):
        with db_session() as db:
            db.query(...)
    """
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


# ── DB health-check ──────────────────────────────────────
def check_db_connection() -> bool:
    """
    Run a lightweight ping against the database.
    Called during app startup to fail fast if DB is unreachable.
    Returns True on success, raises RuntimeError on failure.
    """
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("✅ Database connected successfully.")
        return True
    except Exception as exc:
        logger.critical("❌ Database connection failed: %s", exc)
        raise RuntimeError(f"Cannot connect to database: {exc}") from exc
