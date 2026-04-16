"""
Worker initialization – uses APScheduler for background tasks.
"""

import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.workers.tasks import cleanup_expired_sessions, send_planner_reminders

logger = logging.getLogger(__name__)

# ── Shared scheduler instance ────────────────────────────
scheduler = AsyncIOScheduler()

def start_worker():
    """
    Configure and start the background scheduler.
    Tasks are added here with their specific triggers.
    """
    logger.info("👷 Starting background worker scheduler...")
    
    # Task 1: Cleanup test sessions every hour
    scheduler.add_job(
        cleanup_expired_sessions,
        CronTrigger(hour="*"),  # Run at the start of every hour
        id="cleanup_sessions",
        replace_existing=True
    )
    
    # Task 2: Check for planner reminders every 15 minutes
    scheduler.add_job(
        send_planner_reminders,
        CronTrigger(minute="0,15,30,45"),
        id="planner_reminders",
        replace_existing=True
    )
    
    scheduler.start()
    logger.info("✅ Worker scheduler started and jobs added.")

def stop_worker():
    """Stop the scheduler gracefully."""
    logger.info("🛑 Stopping background worker scheduler...")
    scheduler.shutdown()
