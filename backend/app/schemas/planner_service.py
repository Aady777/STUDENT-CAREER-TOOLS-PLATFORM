"""
Pydantic schemas for Study Planner tasks.
"""

from pydantic import BaseModel, Field
from datetime import date, datetime
from enum import Enum


class PriorityEnum(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class PlannerCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, examples=["Revise Chapter 5"])
    description: str = Field(default="", max_length=1000)
    due_date: date | None = None
    priority: PriorityEnum = PriorityEnum.medium


class PlannerUpdateRequest(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=1000)
    due_date: date | None = None
    priority: PriorityEnum | None = None
    is_completed: bool | None = None


class PlannerResponse(BaseModel):
    id: int
    user_id: int
    title: str
    description: str
    due_date: date | None = None
    priority: str
    is_completed: bool
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}


class PlannerListResponse(BaseModel):
    tasks: list[PlannerResponse]
    total: int
    completed: int
