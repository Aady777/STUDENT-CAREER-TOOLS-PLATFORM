"""
Background / scheduled tasks placeholder.
Can be wired to Celery, APScheduler, or similar.
"""

import logging

logger = logging.getLogger("workers")


def cleanup_expired_sessions():
    """Placeholder – remove expired mock-test sessions."""
    logger.info("Running cleanup_expired_sessions task")
    # TODO: implement session expiry cleanup


def send_planner_reminders():
    """Placeholder – notify users about upcoming due dates."""
    logger.info("Running send_planner_reminders task")
    # TODO: integrate with email / push notifications
