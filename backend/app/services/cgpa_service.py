"""
CGPA calculation service.
"""

from sqlalchemy.orm import Session
from app.models.cgpa import CGPA
from app.models.user import User
from app.schemas.cgpa_service import CGPACalculateRequest
from app.utils.grade_utils import grade_to_point


def calculate_cgpa(subjects: list[dict]) -> float:
    """Compute weighted CGPA from a list of {subject, grade, credits}."""
    total_credits = 0
    total_points = 0.0
    for s in subjects:
        point = grade_to_point(s["grade"])
        credits = s["credits"]
        total_points += point * credits
        total_credits += credits
    if total_credits == 0:
        return 0.0
    return round(total_points / total_credits, 2)


def create_cgpa_record(db: Session, user: User, payload: CGPACalculateRequest) -> CGPA:
    """Calculate CGPA, persist to DB, and return the record."""
    data = [s.model_dump() for s in payload.subjects]
    result = calculate_cgpa(data)
    record = CGPA(user_id=user.id, result=result, data=data)
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def get_cgpa_history(db: Session, user_id: int) -> list[CGPA]:
    """Return all CGPA records for a user, newest first."""
    return (
        db.query(CGPA)
        .filter(CGPA.user_id == user_id)
        .order_by(CGPA.created_at.desc())
        .all()
    )


def delete_cgpa_record(db: Session, record_id: int, user_id: int) -> bool:
    """Delete a specific CGPA record. Returns True if deleted."""
    record = (
        db.query(CGPA)
        .filter(CGPA.id == record_id, CGPA.user_id == user_id)
        .first()
    )
    if not record:
        return False
    db.delete(record)
    db.commit()
    return True
