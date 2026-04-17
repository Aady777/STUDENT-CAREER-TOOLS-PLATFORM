"""
Mock Test routes – CRUD for tests + submit answers.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.test_service import TestCreateRequest, TestResponse, TestListResponse
from app.schemas.evaluation_service import SubmitTestRequest, ResultResponse, ResultListResponse
from app.services import test_service, evaluation_service

router = APIRouter(prefix="/tests", tags=["Mock Tests"])


# ── Test management ──────────────────────────────────────
@router.post("/", response_model=TestResponse, status_code=status.HTTP_201_CREATED)
def create_test(
    body: TestCreateRequest,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return test_service.create_test(db, body)


@router.get("/", response_model=TestListResponse)
def list_tests(
    subject: str | None = Query(default=None),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    tests = test_service.get_tests(db, subject)
    return {"tests": tests, "total": len(tests)}


@router.get("/{test_id}", response_model=TestResponse)
def get_test(
    test_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    test = test_service.get_test(db, test_id)
    if not test:
        raise HTTPException(status_code=404, detail="Test not found")
    return test


@router.delete("/{test_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_test(
    test_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    if not test_service.delete_test(db, test_id):
        raise HTTPException(status_code=404, detail="Test not found")


# ── Submit & Results ─────────────────────────────────────
@router.post("/submit", response_model=ResultResponse, status_code=status.HTTP_201_CREATED)
def submit_test(
    body: SubmitTestRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Submit answers for a test. Backend evaluates and returns score."""
    try:
        return evaluation_service.evaluate_test(db, user.id, body)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/results/me", response_model=ResultListResponse)
def my_results(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    results = evaluation_service.get_user_results(db, user.id)
    return {"results": results, "total": len(results)}
