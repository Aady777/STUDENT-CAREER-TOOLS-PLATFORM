"""
User model – authentication & ownership of all student data.
"""

from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # ── Relationships ────────────────────────────────────
    cgpa_records = relationship("CGPA", back_populates="user", cascade="all, delete-orphan")
    planners = relationship("Planner", back_populates="user", cascade="all, delete-orphan")
    notes = relationship("Note", back_populates="user", cascade="all, delete-orphan")
    results = relationship("Result", back_populates="user", cascade="all, delete-orphan")
    timetables = relationship("Timetable", back_populates="user", cascade="all, delete-orphan")
