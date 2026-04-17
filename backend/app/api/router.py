"""
Central API router – aggregates all feature routers under /api.
"""

from fastapi import APIRouter

from app.api.routes.auth import router as auth_router
from app.api.routes.cgpa import router as cgpa_router
from app.api.routes.planner import router as planner_router
from app.api.routes.notes import router as notes_router
from app.api.routes.test import router as test_router
from app.api.routes.timetable import router as timetable_router
from app.api.routes.analytics import router as analytics_router

api_router = APIRouter(prefix="/api")

api_router.include_router(auth_router)
api_router.include_router(cgpa_router)
api_router.include_router(planner_router)
api_router.include_router(notes_router)
api_router.include_router(test_router)
api_router.include_router(timetable_router)
api_router.include_router(analytics_router)
