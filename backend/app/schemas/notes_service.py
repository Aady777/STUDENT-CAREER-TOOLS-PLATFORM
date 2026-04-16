"""
Pydantic schemas for Notes.
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Any


class NoteCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, examples=["Physics Lecture 3"])
    content: Any = Field(..., description="JSON content from editor")
    tags: str = Field(default="", examples=["physics,lecture,kinematics"])


class NoteUpdateRequest(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    content: Any | None = None
    tags: str | None = None
    attachments: list[dict] | None = None


class NoteResponse(BaseModel):
    id: int
    user_id: int
    title: str
    content: Any
    tags: str
    attachments: list[dict] = []
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}


class NoteListResponse(BaseModel):
    notes: list[NoteResponse]
    total: int


class AttachmentResponse(BaseModel):
    name: str
    stored_name: str
    url: str
    size_bytes: int
    mime_type: str
