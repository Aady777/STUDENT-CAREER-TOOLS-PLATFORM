"""
Student Utility API – FastAPI application entry-point.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.database import engine, Base
from app.api.router import api_router

# ── Import all models so Base.metadata knows about them ──
from app.models import user, cgpa, planner, notes, test, result, timetable  # noqa: F401

settings = get_settings()

# ── Create tables ────────────────────────────────────────
Base.metadata.create_all(bind=engine)

# ── App ──────────────────────────────────────────────────
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="All-in-one student utility – CGPA calculator, study planner, notes, mock tests & timetable.",
    docs_url="/docs",
    redoc_url="/redoc",
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


# ── Health check ─────────────────────────────────────────
@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "app": settings.APP_NAME, "version": settings.APP_VERSION}
