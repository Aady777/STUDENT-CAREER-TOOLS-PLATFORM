"""
Timetable service – CRUD for weekly schedules.
"""

import json
from sqlalchemy.orm import Session
from app.models.timetable import Timetable
from app.schemas.timetable_service import TimetableCreateRequest, TimetableUpdateRequest


def create_timetable(db: Session, user_id: int, payload: TimetableCreateRequest) -> Timetable:
    # Convert SlotSchema objects to dicts for JSON storage
    structure = {
        day: [slot.model_dump() for slot in slots]
        for day, slots in payload.structure.items()
    }
    tt = Timetable(
        user_id=user_id,
        title=payload.title,
        structure=structure,
    )
    db.add(tt)
    db.commit()
    db.refresh(tt)
    return tt


def get_timetables(db: Session, user_id: int) -> list[Timetable]:
    return (
        db.query(Timetable)
        .filter(Timetable.user_id == user_id)
        .order_by(Timetable.created_at.desc())
        .all()
    )


def get_timetable(db: Session, tt_id: int, user_id: int) -> Timetable | None:
    return (
        db.query(Timetable)
        .filter(Timetable.id == tt_id, Timetable.user_id == user_id)
        .first()
    )


def update_timetable(db: Session, tt: Timetable, payload: TimetableUpdateRequest) -> Timetable:
    if payload.title is not None:
        tt.title = payload.title
    if payload.structure is not None:
        tt.structure = {
            day: [slot.model_dump() for slot in slots]
            for day, slots in payload.structure.items()
        }
    db.commit()
    db.refresh(tt)
    return tt


def delete_timetable(db: Session, tt: Timetable) -> None:
    db.delete(tt)
    db.commit()


def export_timetable(tt: Timetable) -> str:
    """Export timetable as formatted JSON string."""
    return json.dumps({"title": tt.title, "schedule": tt.structure}, indent=2)
