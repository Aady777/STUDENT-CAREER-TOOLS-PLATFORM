"""
Evaluation service – evaluate submitted answers and store results.
"""

from sqlalchemy.orm import Session
from app.models.test import Test
from app.models.result import Result
from app.schemas.evaluation_service import SubmitTestRequest


def evaluate_test(db: Session, user_id: int, payload: SubmitTestRequest) -> Result:
    """Score the user's answers against the test and persist the result."""
    test = db.query(Test).filter(Test.id == payload.test_id).first()
    if not test:
        raise ValueError("Test not found")

    questions = test.questions
    total = len(questions)
    correct = 0

    for i, q in enumerate(questions):
        if i < len(payload.answers) and payload.answers[i] == q["correct"]:
            correct += 1

    score = round((correct / total) * 100, 2) if total > 0 else 0.0

    result = Result(
        user_id=user_id,
        test_id=payload.test_id,
        score=score,
        total_questions=total,
        correct_answers=correct,
        answers=payload.answers,
        time_taken_seconds=payload.time_taken_seconds,
    )
    db.add(result)
    db.commit()
    db.refresh(result)
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
