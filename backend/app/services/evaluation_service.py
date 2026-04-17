"""
Evaluation service – evaluate submitted answers and store results.

Now includes Redis session validation to prevent:
  - Submitting after timer expires
  - Submitting with a forged/invalid session token
  - Double-submitting the same test session

Also computes per-topic performance breakdown for analytics.
"""

import logging
from collections import defaultdict

import redis
from sqlalchemy.orm import Session

from app.models.test import Test
from app.models.result import Result
from app.schemas.evaluation_service import SubmitTestRequest
from app.services import session_service

logger = logging.getLogger(__name__)


class TestSessionExpiredError(Exception):
    """Raised when the test session has expired or is invalid."""
    pass


def _compute_topic_breakdown(questions: list[dict], answers: list[int]) -> dict:
    """
    Group questions by their optional 'topic' field and count correct answers.

    Returns a dict like:
        {"Physics": {"total": 5, "correct": 4}, "General": {"total": 2, "correct": 2}}

    Questions without a 'topic' key are grouped under "General".
    """
    breakdown: dict[str, dict[str, int]] = defaultdict(lambda: {"total": 0, "correct": 0})

    for i, q in enumerate(questions):
        topic = q.get("topic") or "General"
        breakdown[topic]["total"] += 1
        if i < len(answers) and answers[i] == q.get("correct"):
            breakdown[topic]["correct"] += 1

    return dict(breakdown)


def evaluate_test(
    db: Session,
    user_id: int,
    payload: SubmitTestRequest,
    redis_client: redis.Redis,
) -> Result:
    """
    Validate session → score answers → persist result → end session.

    Raises:
        ValueError: if test_id doesn't exist
        TestSessionExpiredError: if session is expired or token is invalid
    """
    # ── 1. Validate the Redis session ─────────────────────
    is_valid, reason = session_service.validate_session(
        redis_client=redis_client,
        user_id=user_id,
        test_id=payload.test_id,
        session_token=payload.session_token,
    )
    if not is_valid:
        raise TestSessionExpiredError(reason)

    # ── 2. Fetch the test paper ───────────────────────────
    test = db.query(Test).filter(Test.id == payload.test_id).first()
    if not test:
        raise ValueError("Test not found")

    # ── 3. Score the answers ──────────────────────────────
    questions = test.questions
    total = len(questions)
    correct = 0

    for i, q in enumerate(questions):
        if i < len(payload.answers) and payload.answers[i] == q["correct"]:
            correct += 1

    score = round((correct / total) * 100, 2) if total > 0 else 0.0

    # ── 4. Compute topic-wise breakdown ───────────────────
    topic_breakdown = _compute_topic_breakdown(questions, payload.answers)

    # ── 5. Persist the result ─────────────────────────────
    result = Result(
        user_id=user_id,
        test_id=payload.test_id,
        score=score,
        total_questions=total,
        correct_answers=correct,
        answers=payload.answers,
        time_taken_seconds=payload.time_taken_seconds,
        topic_breakdown=topic_breakdown,
    )
    db.add(result)
    db.commit()
    db.refresh(result)

    # ── 6. End session (prevent double submission) ─────────
    session_service.end_session(
        redis_client=redis_client,
        user_id=user_id,
        test_id=payload.test_id,
    )

    logger.info(
        "Test evaluated | user=%s | test=%s | score=%.1f%% (%d/%d) | topics=%s",
        user_id, payload.test_id, score, correct, total, list(topic_breakdown.keys()),
    )
    return result


def get_user_results(db: Session, user_id: int) -> list[Result]:
    return (
        db.query(Result)
        .filter(Result.user_id == user_id)
        .order_by(Result.created_at.desc())
        .all()
    )


def get_result(db: Session, result_id: int, user_id: int) -> Result | None:
    return (
        db.query(Result)
        .filter(Result.id == result_id, Result.user_id == user_id)
        .first()
    )
