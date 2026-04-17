"""
Redis-based sliding-window rate limiter.

Usage (FastAPI dependency):

    from app.core.rate_limiter import RateLimiter

    @router.post("/login")
    def login(
        request: Request,
        _: None = Depends(RateLimiter(max_requests=5, window_seconds=60)),
    ):
        ...

When the limit is exceeded the dependency raises HTTP 429 Too Many Requests
with a Retry-After header indicating how many seconds remain in the window.
"""

import logging
import time

import redis
from fastapi import Depends, HTTPException, Request, status

from app.core.redis import get_redis

logger = logging.getLogger(__name__)


class RateLimiter:
    """
    Sliding-window rate limiter backed by a Redis sorted-set.

    Each request is recorded as a member of a sorted-set keyed by
    `rate_limit:{identifier}:{route_key}` with the current timestamp as the
    score.  On every call we remove timestamps older than the window and
    count the remainder.

    Args:
        max_requests: Maximum requests allowed within the window.
        window_seconds: Duration of the rolling window in seconds.
        key_prefix: Prefix for the Redis key (default ``"rate_limit"``).
    """

    def __init__(
        self,
        max_requests: int,
        window_seconds: int,
        key_prefix: str = "rate_limit",
    ):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.key_prefix = key_prefix

    def __call__(
        self,
        request: Request,
        redis_client: redis.Redis = Depends(get_redis),
    ) -> None:
        """FastAPI dependency — raises HTTP 429 if the limit is breached."""
        # Identify caller by their real IP (handles X-Forwarded-For proxies)
        client_ip = (
            request.headers.get("X-Forwarded-For", "").split(",")[0].strip()
            or (request.client.host if request.client else "unknown")
        )
        route_key = request.url.path.replace("/", "_")
        redis_key = f"{self.key_prefix}:{client_ip}:{route_key}"

        now = time.time()
        window_start = now - self.window_seconds

        try:
            pipe = redis_client.pipeline()
            # Remove entries outside the current window
            pipe.zremrangebyscore(redis_key, 0, window_start)
            # Count remaining entries (requests in the current window)
            pipe.zcard(redis_key)
            # Add this request
            pipe.zadd(redis_key, {str(now): now})
            # Expire the key slightly beyond the window to allow GC
            pipe.expire(redis_key, self.window_seconds + 10)
            _, current_count, _, _ = pipe.execute()
        except Exception as exc:
            # If Redis is down, fail open (don't block the request)
            logger.warning("Rate limiter Redis error (fail-open): %s", exc)
            return

        if current_count >= self.max_requests:
            retry_after = self.window_seconds
            logger.warning(
                "Rate limit exceeded | ip=%s | route=%s | count=%d/%d",
                client_ip, route_key, current_count, self.max_requests,
            )
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    f"Too many requests. "
                    f"Limit: {self.max_requests} per {self.window_seconds}s. "
                    f"Retry after {retry_after}s."
                ),
                headers={"Retry-After": str(retry_after)},
            )
