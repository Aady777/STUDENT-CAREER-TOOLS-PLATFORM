"""
CGPA model – stores semester-wise subject grades and calculated CGPA.
"""

from sqlalchemy import Column, Integer, Float, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class CGPA(Base):
    __tablename__ = "cgpa"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    result = Column(Float, nullable=False)          # calculated CGPA value
    data = Column(JSON, nullable=False)              # list of {subject, grade, credits}
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="cgpa_records")
