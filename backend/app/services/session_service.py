"""
Test Session Service – Redis-based timer management for Mock Tests.

Flow:
  1. User calls POST /tests/{test_id}/start
     → Backend stores a session key in Redis with TTL = duration_minutes
     → Returns a session_token to the client

  2. User calls POST /tests/submit
     → Sends back answers + session_token
     → Backend validates the token still exists in Redis (not expired)
     → If expired → 408 Request Timeout (cheating prevention)
     → If valid   → evaluates answers, deletes session key, stores result

Redis key format:
    test_session:{user_id}:{test_id}  →  {session_token}  (TTL = duration_seconds)
"""

import uuid
import logging

import redis

logger = logging.getLogger(__name__)

# ── Key helpers ───────────────────────────────────────────
def _session_key(user_id: int, test_id: int) -> str:
    return f"test_session:{user_id}:{test_id}"


# ── Start session ─────────────────────────────────────────
def start_session(
    redis_client: redis.Redis,
    user_id: int,
    test_id: int,
    duration_minutes: int,
) -> str:
    """
    Create a new test session in Redis.

    - Generates a unique session_token (UUID4).
    - Stores it with TTL = duration_minutes * 60 seconds.
    - If the user already has an active session for this test,
      it is overwritten (allows retaking / recovering from crash).

    Returns the session_token string.
    """
    token = str(uuid.uuid4())
    key = _session_key(user_id, test_id)
    ttl_seconds = duration_minutes * 60

    redis_client.setex(name=key, time=ttl_seconds, value=token)
    logger.info(
        "Test session started | user=%s | test=%s | TTL=%ss | token=%s",
        user_id, test_id, ttl_seconds, token,
    )
    return token


# ── Validate session ──────────────────────────────────────
def validate_session(
    redis_client: redis.Redis,
    user_id: int,
    test_id: int,
    session_token: str,
) -> tuple[bool, str]:
    """
    Validate that the session_token is still alive and matches.

    Returns (is_valid: bool, reason: str).

    Failure cases:
      - Key missing  → timer expired (cheating attempt or genuine timeout)
      - Token mismatch → someone tampered with the token
    """
    key = _session_key(user_id, test_id)
    stored_token = redis_client.get(key)

    if stored_token is None:
        logger.warning(
            "Session expired or not found | user=%s | test=%s", user_id, test_id
        )
        return False, "Test session has expired. Time limit exceeded."

    if stored_token != session_token:
        logger.warning(
            "Session token mismatch | user=%s | test=%s", user_id, test_id
        )
        return False, "Invalid session token. Submission rejected."

    # Check remaining time for logging
    remaining = redis_client.ttl(key)
    logger.info(
        "Session valid | user=%s | test=%s | %ss remaining", user_id, test_id, remaining
    )
    return True, "ok"


# ── End session ───────────────────────────────────────────
def end_session(
    redis_client: redis.Redis,
    user_id: int,
    test_id: int,
) -> None:
    """
    Delete the session key after a successful submission.
    Prevents the same session being reused for double submission.
    """
    key = _session_key(user_id, test_id)
    redis_client.delete(key)
    logger.info("Session ended | user=%s | test=%s", user_id, test_id)


# ── Get remaining time ────────────────────────────────────
def get_remaining_seconds(
    redis_client: redis.Redis,
    user_id: int,
    test_id: int,
) -> int | None:
    """
    Return remaining seconds for an active session, or None if not found.
    Useful for a 'time remaining' API call from the frontend.
    """
    key = _session_key(user_id, test_id)
    ttl = redis_client.ttl(key)
    return ttl if ttl > 0 else None
