"""
Pydantic schemas for Mock Tests.
"""

from pydantic import BaseModel, Field
from datetime import datetime


class QuestionSchema(BaseModel):
    question: str = Field(..., min_length=1)
    options: list[str] = Field(..., min_length=2, max_length=6)
    correct: int = Field(..., ge=0, description="Index of the correct option")


class TestCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, examples=["Chemistry Unit Test 1"])
    subject: str = Field(default="General", max_length=100)
    duration_minutes: int = Field(default=30, ge=1, le=300)
    questions: list[QuestionSchema] = Field(..., min_length=1)


class TestResponse(BaseModel):
    id: int
    title: str
    subject: str
    duration_minutes: int
    questions: list[dict]
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class TestListResponse(BaseModel):
    tests: list[TestResponse]
    total: int
