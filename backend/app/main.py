"""
Student Utility API – FastAPI application entry-point.
"""

import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.core.config import get_settings
from app.core.database import engine, Base, check_db_connection
from app.core.redis import check_redis_connection
from app.api.router import api_router

# ── Import all models so Base.metadata knows about them ──
from app.models import user, cgpa, planner, notes, test, result, timetable  # noqa: F401

settings = get_settings()
logger = logging.getLogger(__name__)

# ── Logging setup ─────────────────────────────────────────
logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)


# ── Lifespan: startup & shutdown ─────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Runs once on startup (before serving requests) and once on shutdown.
    - Creates all DB tables if they don't exist
    - Verifies DB & Redis connectivity
    """
    logger.info("🚀 Starting %s v%s …", settings.APP_NAME, settings.APP_VERSION)

    # 1. Create tables (idempotent – safe to run on every restart)
    Base.metadata.create_all(bind=engine)
    logger.info("✅ Database tables verified / created.")

    # 2. Verify DB is reachable (will raise RuntimeError if not)
    check_db_connection()

    # 3. Verify Redis (non-fatal warning if unavailable)
    check_redis_connection()

    yield   # ── app is now live and serving ──────────────

    # Shutdown – dispose the connection pool cleanly
    engine.dispose()
    logger.info("🛑 %s shut down. DB pool disposed.", settings.APP_NAME)


# ── App ──────────────────────────────────────────────────
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=(
        "All-in-one student utility – CGPA calculator, study planner, "
        "notes, mock tests & timetable."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# ── CORS ─────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Mount routes ─────────────────────────────────────────
app.include_router(api_router)

# ── Serve uploaded files ──────────────────────────────────
UPLOAD_DIR = Path("/app/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")


# ── Health check ─────────────────────────────────────────
@app.get("/health", tags=["Health"], summary="Service health status")
def health():
    """
    Returns DB and Redis connectivity status alongside app metadata.
    Useful for Docker health checks and monitoring dashboards.
    """
    db_ok = True
    redis_ok = True

    try:
        check_db_connection()
    except RuntimeError:
        db_ok = False

    try:
        from app.core.redis import get_redis_client
        get_redis_client().ping()
    except Exception:
        redis_ok = False

    overall = "ok" if (db_ok and redis_ok) else "degraded"

    return JSONResponse(
        status_code=200 if overall == "ok" else 207,
        content={
            "status": overall,
            "app": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "services": {
                "database": "✅ connected" if db_ok else "❌ unreachable",
                "redis":    "✅ connected" if redis_ok else "⚠️  unreachable",
            },
        },
    )
