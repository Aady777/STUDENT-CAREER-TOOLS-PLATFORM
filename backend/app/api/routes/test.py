"""
Mock Test routes – CRUD for tests + session-based submit with Redis timer.

New endpoints:
  POST /tests/{test_id}/start       → start a timed session (Redis)
  GET  /tests/{test_id}/time        → check remaining seconds
  POST /tests/submit                → submit answers (validated against Redis)

Rate limiting:
  POST /tests/submit                → 10 requests / 60 s per IP
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
import redis

from app.core.dependencies import get_db, get_current_user
from app.core.redis import get_redis
from app.core.rate_limiter import RateLimiter
from app.core.config import get_settings
from app.models.user import User

settings = get_settings()
_submit_limiter = RateLimiter(
    max_requests=settings.RATE_LIMIT_SUBMIT_MAX,
    window_seconds=settings.RATE_LIMIT_SUBMIT_WINDOW,
)
from app.schemas.test_service import (
    TestCreateRequest,
    TestResponse,
    TestListResponse,
    StartTestResponse,
)
from app.schemas.evaluation_service import (
    SubmitTestRequest,
    ResultResponse,
    ResultListResponse,
)
from app.services import test_service, evaluation_service, session_service
from app.services.evaluation_service import TestSessionExpiredError

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


# ── Session-based test flow ──────────────────────────────

@router.post(
    "/{test_id}/start",
    response_model=StartTestResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Start a timed test session",
)
def start_test_session(
    test_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    redis_client: redis.Redis = Depends(get_redis),
):
    """
    Starts a timed test session for the current user.

    - Stores a session token in Redis with TTL = test.duration_minutes
    - The frontend must send this token back when submitting answers
    - If the timer expires before submission, the submission is rejected
    """
    test = test_service.get_test(db, test_id)
    if not test:
        raise HTTPException(status_code=404, detail="Test not found")

    token = session_service.start_session(
        redis_client=redis_client,
        user_id=user.id,
        test_id=test_id,
        duration_minutes=test.duration_minutes,
    )

    return StartTestResponse(
        test_id=test_id,
        session_token=token,
        duration_minutes=test.duration_minutes,
        expires_in_seconds=test.duration_minutes * 60,
    )


@router.get(
    "/{test_id}/time",
    summary="Get remaining time for active session",
)
def get_remaining_time(
    test_id: int,
    user: User = Depends(get_current_user),
    redis_client: redis.Redis = Depends(get_redis),
):
    """
    Returns the seconds remaining in the user's active test session.
    Returns 0 if no session exists (expired or not started).
    """
    remaining = session_service.get_remaining_seconds(
        redis_client=redis_client,
        user_id=user.id,
        test_id=test_id,
    )
    return {
        "test_id": test_id,
        "remaining_seconds": remaining or 0,
        "active": remaining is not None,
    }


# ── Submit & Results ─────────────────────────────────────
@router.post(
    "/submit",
    response_model=ResultResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit answers (session validated via Redis)",
    dependencies=[Depends(_submit_limiter)],
)
def submit_test(
    body: SubmitTestRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
    redis_client: redis.Redis = Depends(get_redis),
):
    """
    Submit answers for a test.

    - Validates the session_token against Redis
    - If timer expired → 408 Request Timeout
    - If token invalid → 403 Forbidden
    - If valid → evaluates, stores result, ends session
    """
    try:
        return evaluation_service.evaluate_test(
            db=db,
            user_id=user.id,
            payload=body,
            redis_client=redis_client,
        )
    except TestSessionExpiredError as e:
        raise HTTPException(status_code=408, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/results/me", response_model=ResultListResponse)
def my_results(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    results = evaluation_service.get_user_results(db, user.id)
    return {"results": results, "total": len(results)}
