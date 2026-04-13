"""
Pydantic schemas for Timetable.
"""

from pydantic import BaseModel, Field
from datetime import datetime


class SlotSchema(BaseModel):
    time: str = Field(..., examples=["09:00-10:00"])
    subject: str = Field(..., examples=["Mathematics"])
    room: str = Field(default="", examples=["A-101"])


class TimetableCreateRequest(BaseModel):
    title: str = Field(default="My Timetable", max_length=255)
    structure: dict[str, list[SlotSchema]] = Field(
        ...,
        examples=[{
            "Monday": [{"time": "09:00-10:00", "subject": "Maths", "room": "A101"}],
            "Tuesday": [],
        }],
    )


class TimetableUpdateRequest(BaseModel):
    title: str | None = Field(default=None, max_length=255)
    structure: dict[str, list[SlotSchema]] | None = None


class TimetableResponse(BaseModel):
    id: int
    user_id: int
    title: str
    structure: dict
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}


class TimetableListResponse(BaseModel):
    timetables: list[TimetableResponse]
    total: int
