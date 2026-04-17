"""
Mock-test service – CRUD for test papers.
"""

from sqlalchemy.orm import Session
from app.models.test import Test
from app.schemas.test_service import TestCreateRequest


def create_test(db: Session, payload: TestCreateRequest) -> Test:
    test = Test(
        title=payload.title,
        subject=payload.subject,
        duration_minutes=payload.duration_minutes,
        questions=[q.model_dump() for q in payload.questions],
    )
    db.add(test)
    db.commit()
    db.refresh(test)
    return test


def get_tests(db: Session, subject: str | None = None) -> list[Test]:
    query = db.query(Test)
    if subject:
        query = query.filter(Test.subject.ilike(f"%{subject}%"))
    return query.order_by(Test.created_at.desc()).all()


def get_test(db: Session, test_id: int) -> Test | None:
    return db.query(Test).filter(Test.id == test_id).first()


def delete_test(db: Session, test_id: int) -> bool:
    test = db.query(Test).filter(Test.id == test_id).first()
    if not test:
        return False
    db.delete(test)
    db.commit()
    return True
