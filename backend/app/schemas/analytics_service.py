"""
Pydantic schemas for Test Analytics responses.
"""

from pydantic import BaseModel, Field
from datetime import datetime


class TopicBreakdown(BaseModel):
    """Per-topic performance for a single test attempt."""
    topic: str
    total: int
    correct: int
    accuracy: float = Field(..., description="Percentage 0–100")


class SubjectAnalytics(BaseModel):
    """Aggregated analytics for a single subject across all attempts."""
    subject: str
    total_attempts: int
    avg_score: float
    best_score: float
    topic_breakdowns: list[TopicBreakdown] = []


class ProgressPoint(BaseModel):
    """One data-point on the student's score timeline."""
    result_id: int
    test_id: int
    subject: str
    score: float
    created_at: datetime | None = None


class AnalyticsSummary(BaseModel):
    """Overall analytics summary across all subjects."""
    total_tests_taken: int
    average_score: float
    best_score: float
    worst_score: float
    subject_analytics: list[SubjectAnalytics] = []
    recent_progress: list[ProgressPoint] = []
