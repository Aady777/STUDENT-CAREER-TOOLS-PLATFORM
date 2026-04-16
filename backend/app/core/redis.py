"""
Redis connection helper.

Provides a single shared client instance and a FastAPI dependency.
"""

import logging
import redis
from redis.exceptions import ConnectionError as RedisConnectionError

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


# ── Shared client (lazy connect) ─────────────────────────
_redis_client: redis.Redis | None = None


def get_redis_client() -> redis.Redis:
    """
    Return a shared Redis client (creates it once on first call).
    decode_responses=True → all keys/values are Python strings.
    """
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            db=settings.REDIS_DB,
            password=settings.REDIS_PASSWORD,
            decode_responses=True,
            socket_connect_timeout=5,      # fail fast if Redis is down
            socket_timeout=5,
            retry_on_timeout=True,
        )
    return _redis_client


# ── FastAPI dependency ────────────────────────────────────
def get_redis() -> redis.Redis:
    """
    FastAPI dependency – yields the Redis client.
    Usage:
        redis: Redis = Depends(get_redis)
    """
    return get_redis_client()


# ── Health check ─────────────────────────────────────────
def check_redis_connection() -> bool:
    """
    Ping Redis to verify connectivity.
    Called during app startup to fail fast if Redis is unreachable.
    """
    try:
        client = get_redis_client()
        client.ping()
        logger.info("✅ Redis connected successfully.")
        return True
    except RedisConnectionError as exc:
        logger.warning("⚠️  Redis unavailable (non-fatal): %s", exc)
        return False
