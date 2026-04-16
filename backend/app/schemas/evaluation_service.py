"""
Pydantic schemas for Test Evaluation / Results.
"""

from pydantic import BaseModel, Field
from datetime import datetime


class SubmitTestRequest(BaseModel):
    test_id: int
    answers: list[int] = Field(..., description="List of chosen option indices")
    time_taken_seconds: int | None = Field(default=None, ge=0)


class ResultResponse(BaseModel):
    id: int
    user_id: int
    test_id: int
    score: float
    total_questions: int
    correct_answers: int
    answers: list[int] | None = None
    time_taken_seconds: int | None = None
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class ResultListResponse(BaseModel):
    results: list[ResultResponse]
    total: int
