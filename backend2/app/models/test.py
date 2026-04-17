"""
Test model – mock tests with questions stored as JSON.
"""

from sqlalchemy import Column, Integer, String, JSON, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Test(Base):
    __tablename__ = "tests"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    subject = Column(String(100), default="General")
    duration_minutes = Column(Integer, default=30)
    questions = Column(JSON, nullable=False)
    """
    questions schema:
    [
        {
            "question": "What is …?",
            "options": ["A", "B", "C", "D"],
            "correct": 0          # index of correct option
        },
        …
    ]
    """
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    results = relationship("Result", back_populates="test", cascade="all, delete-orphan")
