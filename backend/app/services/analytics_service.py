"""
Analytics service – aggregate long-term student performance data.

Functions:
  get_summary(db, user_id) → overall stats (avg score, subject breakdown)
  get_progress(db, user_id, limit) → time-series of recent scores
  get_subject_analytics(db, user_id, subject) → per-subject topic breakdown
"""

import logging
from collections import defaultdict

from sqlalchemy.orm import Session

from app.models.result import Result
from app.models.test import Test
from app.schemas.analytics_service import (
    AnalyticsSummary,
    SubjectAnalytics,
    TopicBreakdown,
    ProgressPoint,
)

logger = logging.getLogger(__name__)


def get_summary(db: Session, user_id: int) -> AnalyticsSummary:
    """
    Return an overall analytics summary for the user.

    Aggregates across all test results:
      - Total tests taken, avg/best/worst score
      - Per-subject breakdown with topic accuracy
      - 10 most recent progress points
    """
    results = (
        db.query(Result, Test.subject)
        .join(Test, Result.test_id == Test.id)
        .filter(Result.user_id == user_id)
        .order_by(Result.created_at.desc())
        .all()
    )

    if not results:
        return AnalyticsSummary(
            total_tests_taken=0,
            average_score=0.0,
            best_score=0.0,
            worst_score=0.0,
        )

    scores = [r.score for r, _ in results]
    total = len(scores)
    avg_score = round(sum(scores) / total, 2)
    best_score = round(max(scores), 2)
    worst_score = round(min(scores), 2)

    # ── Build per-subject aggregation ────────────────────
    # subject → { scores: [], topics: { topic: {total, correct} } }
    subject_map: dict[str, dict] = defaultdict(lambda: {"scores": [], "topics": defaultdict(lambda: {"total": 0, "correct": 0})})

    for result, subject in results:
        subj = subject or "General"
        subject_map[subj]["scores"].append(result.score)
        # Merge topic breakdowns
        if result.topic_breakdown:
            for topic, counts in result.topic_breakdown.items():
                subject_map[subj]["topics"][topic]["total"] += counts.get("total", 0)
                subject_map[subj]["topics"][topic]["correct"] += counts.get("correct", 0)

    subject_analytics = []
    for subj, data in subject_map.items():
        topic_list = []
        for topic, counts in data["topics"].items():
            t = counts["total"]
            c = counts["correct"]
            accuracy = round((c / t * 100), 2) if t > 0 else 0.0
            topic_list.append(TopicBreakdown(topic=topic, total=t, correct=c, accuracy=accuracy))
        subj_scores = data["scores"]
        subject_analytics.append(SubjectAnalytics(
            subject=subj,
            total_attempts=len(subj_scores),
            avg_score=round(sum(subj_scores) / len(subj_scores), 2),
            best_score=round(max(subj_scores), 2),
            topic_breakdowns=sorted(topic_list, key=lambda x: x.topic),
        ))

    # ── Recent progress (last 10 results) ────────────────
    recent_progress = [
        ProgressPoint(
            result_id=r.id,
            test_id=r.test_id,
            subject=subj or "General",
            score=r.score,
            created_at=r.created_at,
        )
        for r, subj in results[:10]
    ]

    return AnalyticsSummary(
        total_tests_taken=total,
        average_score=avg_score,
        best_score=best_score,
        worst_score=worst_score,
        subject_analytics=sorted(subject_analytics, key=lambda x: x.subject),
        recent_progress=recent_progress,
    )


def get_progress(db: Session, user_id: int, limit: int = 20) -> list[ProgressPoint]:
    """Return the most recent `limit` result progress points for charting."""
    rows = (
        db.query(Result, Test.subject)
        .join(Test, Result.test_id == Test.id)
        .filter(Result.user_id == user_id)
        .order_by(Result.created_at.desc())
        .limit(limit)
        .all()
    )
    return [
        ProgressPoint(
            result_id=r.id,
            test_id=r.test_id,
            subject=subj or "General",
            score=r.score,
            created_at=r.created_at,
        )
        for r, subj in rows
    ]


def get_subject_analytics(db: Session, user_id: int, subject: str) -> SubjectAnalytics:
    """
    Return detailed analytics for a specific subject.
    Aggregates topic-wise accuracy across all attempts for that subject.
    """
    rows = (
        db.query(Result)
        .join(Test, Result.test_id == Test.id)
        .filter(Result.user_id == user_id, Test.subject.ilike(f"%{subject}%"))
        .order_by(Result.created_at.desc())
        .all()
    )

    if not rows:
        return SubjectAnalytics(
            subject=subject,
            total_attempts=0,
            avg_score=0.0,
            best_score=0.0,
        )

    scores = [r.score for r in rows]
    topics: dict[str, dict[str, int]] = defaultdict(lambda: {"total": 0, "correct": 0})

    for result in rows:
        if result.topic_breakdown:
            for topic, counts in result.topic_breakdown.items():
                topics[topic]["total"] += counts.get("total", 0)
                topics[topic]["correct"] += counts.get("correct", 0)

    topic_list = []
    for topic, counts in topics.items():
        t = counts["total"]
        c = counts["correct"]
        accuracy = round((c / t * 100), 2) if t > 0 else 0.0
        topic_list.append(TopicBreakdown(topic=topic, total=t, correct=c, accuracy=accuracy))

    return SubjectAnalytics(
        subject=subject,
        total_attempts=len(rows),
        avg_score=round(sum(scores) / len(scores), 2),
        best_score=round(max(scores), 2),
        topic_breakdowns=sorted(topic_list, key=lambda x: x.accuracy, reverse=True),
    )
