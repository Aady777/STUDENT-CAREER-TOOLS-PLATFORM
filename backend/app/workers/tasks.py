"""
Background / scheduled tasks implementation.
"""

import logging
from datetime import date
from sqlalchemy import and_
from app.core.database import db_session
from app.models.planner import Planner

logger = logging.getLogger("workers")


def cleanup_expired_sessions():
    """
    Remove expired mock-test sessions.
    Note: Redis TTL handles automatic expiry of the session tokens.
    This task can be used for secondary cleanup or status syncing.
    """
    logger.info("🧹 Running background task: cleanup_expired_sessions")
    # Redis takes care of the tokens. 
    # If we had a 'sessions' table in DB, we would query and delete expired rows here.
    pass


def send_planner_reminders():
    """
    Identify tasks due today that are not completed and log them.
    In a real system, this would trigger Email, Push, or SMS notifications.
    """
    logger.info("⏰ Running background task: send_planner_reminders")
    
    with db_session() as db:
        today = date.today()
        pending_tasks = (
            db.query(Planner)
            .filter(
                and_(
                    Planner.due_date == today,
                    Planner.is_completed == False
                )
            )
            .all()
        )
        
        if not pending_tasks:
            logger.info("No pending tasks due today.")
            return

        for task in pending_tasks:
            # Simulate notification logic
            logger.info(
                "REMINDER: Task '%s' (User ID: %s) is due today! Priority: %s",
                task.title, task.user_id, task.priority
            )
            # TODO: Integrate with real Notification Service (SMTP/Firebase)
            
        logger.info("Successfully processed %d reminders.", len(pending_tasks))
