"""
Timer utility – helpers for mock-test countdown logic.
"""

from datetime import datetime, timezone


def remaining_seconds(start_time: datetime, duration_minutes: int) -> int:
    """Return seconds remaining from start_time given a duration, or 0 if expired."""
    now = datetime.now(timezone.utc)
    elapsed = (now - start_time).total_seconds()
    remaining = (duration_minutes * 60) - elapsed
    return max(int(remaining), 0)


def is_expired(start_time: datetime, duration_minutes: int) -> bool:
    """Check whether a timed session has expired."""
    return remaining_seconds(start_time, duration_minutes) <= 0


def format_duration(seconds: int) -> str:
    """Format seconds into a human-readable mm:ss string."""
    m, s = divmod(seconds, 60)
    return f"{m:02d}:{s:02d}"
