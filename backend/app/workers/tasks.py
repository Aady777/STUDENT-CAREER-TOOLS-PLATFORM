"""
Background / scheduled tasks implementation.

Tasks:
  - cleanup_expired_sessions  : hourly – Redis TTL already handles expiry,
                                this logs stats and can do DB-side sync.
  - send_planner_reminders    : every 15 min – finds tasks due today and
                                sends email notifications via notification_service.
"""

import logging
from datetime import date

from sqlalchemy import and_

from app.core.database import db_session
from app.models.planner import Planner
from app.models.user import User
from app.services.notification_service import send_reminder_email

logger = logging.getLogger("workers")


def cleanup_expired_sessions() -> None:
    """
    Periodic cleanup task for expired mock-test sessions.

    Redis TTL automatically expires session keys, so no manual deletion
    is needed for the in-memory store.  This task exists for:
      - Logging / observability
      - Future extension: syncing a DB-side 'active_sessions' table
    """
    logger.info("🧹 Running background task: cleanup_expired_sessions")
    # Redis handles TTL-based expiry automatically.
    # If a DB 'sessions' table is added later, we would query and prune here.
    logger.info("cleanup_expired_sessions: Redis TTL managing session expiry — no DB action needed.")


def send_planner_reminders() -> None:
    """
    Find all study-planner tasks due today that are not yet completed,
    then send email reminders to the task owners via the notification service.

    If NOTIFICATIONS_ENABLED=False (default), emails are skipped and reminders
    are only logged — so this task is always safe to run without SMTP config.
    """
    logger.info("⏰ Running background task: send_planner_reminders")

    with db_session() as db:
        today = date.today()

        # Join with User so we have the email address for notifications
        pending = (
            db.query(Planner, User.email)
            .join(User, Planner.user_id == User.id)
            .filter(
                and_(
                    Planner.due_date == today,
                    Planner.is_completed == False,  # noqa: E712
                )
            )
            .all()
        )

        if not pending:
            logger.info("send_planner_reminders: No tasks due today — nothing to do.")
            return

        sent = 0
        for task, user_email in pending:
            logger.info(
                "REMINDER | user=%s | task='%s' | priority=%s",
                task.user_id, task.title, task.priority,
            )
            # Attempt to send a real email; no-op if notifications disabled
            success = send_reminder_email(
                to_email=user_email,
                task_title=task.title,
                due_date=str(today),
                priority=task.priority or "medium",
            )
            if success:
                sent += 1

        logger.info(
            "send_planner_reminders: processed %d task(s), %d email(s) sent.",
            len(pending), sent,
        )
