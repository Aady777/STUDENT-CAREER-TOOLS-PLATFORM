"""
Pydantic schemas for Notes.
"""

from pydantic import BaseModel, Field
from datetime import datetime


class NoteCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, examples=["Physics Lecture 3"])
    content: str = Field(..., min_length=1)
    tags: str = Field(default="", examples=["physics,lecture,kinematics"])


class NoteUpdateRequest(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    content: str | None = None
    tags: str | None = None


class NoteResponse(BaseModel):
    id: int
    user_id: int
    title: str
    content: str
    tags: str
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}


class NoteListResponse(BaseModel):
    notes: list[NoteResponse]
    total: int
