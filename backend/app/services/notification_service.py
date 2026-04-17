"""
Notification Service – SMTP email delivery for background task reminders.

Usage:
    from app.services.notification_service import send_reminder_email

    send_reminder_email(
        to_email="student@example.com",
        task_title="Revise Chapter 5",
        due_date="2025-01-15",
        priority="high",
    )

Configuration (in .env):
    NOTIFICATIONS_ENABLED=True
    SMTP_HOST=smtp.gmail.com
    SMTP_PORT=587
    SMTP_USER=your-email@gmail.com
    SMTP_PASSWORD=your-app-password
    SMTP_FROM=noreply@student-utility.app

If NOTIFICATIONS_ENABLED is False (the default), all functions are no-ops
that only log – so the app works without any SMTP credentials configured.
"""

import logging
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


def _build_reminder_html(task_title: str, due_date: str, priority: str) -> str:
    """Build a simple HTML email body for a study planner reminder."""
    priority_colours = {"high": "#e74c3c", "medium": "#f39c12", "low": "#27ae60"}
    colour = priority_colours.get(priority.lower(), "#3498db")
    return f"""
    <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: auto;">
        <div style="background: {colour}; padding: 20px; border-radius: 8px 8px 0 0;">
          <h2 style="color: white; margin: 0;">📚 Study Reminder</h2>
        </div>
        <div style="border: 1px solid #ddd; border-top: none; padding: 24px; border-radius: 0 0 8px 8px;">
          <p>You have a pending study task due <strong>today</strong>:</p>
          <table style="width:100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 8px; color: #666;">Task</td>
              <td style="padding: 8px; font-weight: bold;">{task_title}</td>
            </tr>
            <tr style="background: #f9f9f9;">
              <td style="padding: 8px; color: #666;">Due Date</td>
              <td style="padding: 8px;">{due_date}</td>
            </tr>
            <tr>
              <td style="padding: 8px; color: #666;">Priority</td>
              <td style="padding: 8px;">
                <span style="background:{colour}; color:white; padding: 2px 10px;
                             border-radius: 12px; font-size: 12px;">
                  {priority.upper()}
                </span>
              </td>
            </tr>
          </table>
          <p style="color:#999; font-size:12px; margin-top: 24px;">
            You're receiving this because you have an outstanding task in
            your Student Utility study planner.
          </p>
        </div>
      </body>
    </html>
    """


def send_reminder_email(
    to_email: str,
    task_title: str,
    due_date: str,
    priority: str = "medium",
) -> bool:
    """
    Send a study-planner reminder email via SMTP.

    Returns True on success, False on failure.
    Is a no-op (returns False) if NOTIFICATIONS_ENABLED=False.
    """
    if not settings.NOTIFICATIONS_ENABLED:
        logger.debug(
            "Notifications disabled – skipping email to %s for task '%s'",
            to_email, task_title,
        )
        return False

    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        logger.warning("SMTP credentials not configured. Cannot send reminder email.")
        return False

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"📚 Reminder: '{task_title}' is due today!"
        msg["From"] = settings.SMTP_FROM
        msg["To"] = to_email

        html_body = _build_reminder_html(task_title, str(due_date), priority)
        plain_body = (
            f"Study Reminder\n\n"
            f"Task: {task_title}\n"
            f"Due: {due_date}\n"
            f"Priority: {priority.upper()}\n\n"
            f"Don't forget to complete this task today!"
        )

        msg.attach(MIMEText(plain_body, "plain"))
        msg.attach(MIMEText(html_body, "html"))

        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.ehlo()
            server.starttls()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(settings.SMTP_FROM, to_email, msg.as_string())

        logger.info("Reminder email sent | to=%s | task='%s'", to_email, task_title)
        return True

    except smtplib.SMTPAuthenticationError:
        logger.error("SMTP authentication failed. Check SMTP_USER and SMTP_PASSWORD.")
    except smtplib.SMTPException as exc:
        logger.error("SMTP error sending to %s: %s", to_email, exc)
    except Exception as exc:
        logger.error("Unexpected error sending email to %s: %s", to_email, exc)

    return False
