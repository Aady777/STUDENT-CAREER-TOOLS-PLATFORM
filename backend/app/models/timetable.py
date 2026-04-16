"""
Timetable model – weekly class schedule stored as structured JSON.
"""

from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Timetable(Base):
    __tablename__ = "timetables"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), default="My Timetable")
    structure = Column(JSON, nullable=False)
    """
    structure schema:
    {
        "Monday":    [{"time": "09:00-10:00", "subject": "Maths", "room": "A101"}],
        "Tuesday":   [...],
        ...
    }
    """
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="timetables")
