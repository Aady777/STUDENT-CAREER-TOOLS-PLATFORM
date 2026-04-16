"""
Pydantic schemas for CGPA calculation requests & responses.
"""

from pydantic import BaseModel, Field
from datetime import datetime


class SubjectGrade(BaseModel):
    subject: str = Field(..., min_length=1, examples=["Mathematics"])
    grade: str = Field(..., min_length=1, examples=["A+"])
    credits: int = Field(..., ge=1, le=10, examples=[4])


class CGPACalculateRequest(BaseModel):
    subjects: list[SubjectGrade] = Field(..., min_length=1)


class CGPAResponse(BaseModel):
    id: int
    user_id: int
    result: float
    data: list[dict]
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class CGPAHistoryResponse(BaseModel):
    records: list[CGPAResponse]
    total: int
