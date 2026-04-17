"""
Result model – stores a user's score for a specific mock test attempt.
"""

from sqlalchemy import Column, Integer, Float, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Result(Base):
    __tablename__ = "results"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    test_id = Column(Integer, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False, index=True)
    score = Column(Float, nullable=False)             # percentage 0–100
    total_questions = Column(Integer, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    answers = Column(JSON, nullable=True)              # user's submitted answers
    time_taken_seconds = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="results")
    test = relationship("Test", back_populates="results")
