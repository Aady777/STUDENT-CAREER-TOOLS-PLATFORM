"""
Analytics routes – student progress tracking API.

Endpoints:
  GET /analytics/summary              → overall stats + subject breakdown
  GET /analytics/progress             → time-series of recent scores
  GET /analytics/subject/{subject}    → detailed per-subject topic accuracy
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.analytics_service import AnalyticsSummary, SubjectAnalytics, ProgressPoint
from app.services import analytics_service

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get(
    "/summary",
    response_model=AnalyticsSummary,
    summary="Overall student performance summary",
)
def summary(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Returns aggregated stats across all tests:
    - Total attempts, average/best/worst score
    - Per-subject breakdown (attempts, avg score)
    - Topic-wise accuracy (if questions carry a 'topic' field)
    - Last 10 results as a progress timeline
    """
    return analytics_service.get_summary(db, user.id)


@router.get(
    "/progress",
    response_model=list[ProgressPoint],
    summary="Score history for charting",
)
def progress(
    limit: int = Query(default=20, ge=1, le=100, description="Max data-points to return"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Returns recent test scores in chronological order (newest first).
    Ideal for a frontend progress chart.
    """
    return analytics_service.get_progress(db, user.id, limit)


@router.get(
    "/subject/{subject}",
    response_model=SubjectAnalytics,
    summary="Per-subject detailed analytics",
)
def subject_analytics(
    subject: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Returns analytics filtered to one subject:
    - Attempt count, avg/best score
    - Topic-wise accuracy sorted by weakest topic first
    """
    return analytics_service.get_subject_analytics(db, user.id, subject)
