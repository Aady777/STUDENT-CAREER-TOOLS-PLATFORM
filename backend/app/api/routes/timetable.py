"""
Timetable routes – CRUD + export.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import PlainTextResponse
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.timetable_service import (
    TimetableCreateRequest,
    TimetableUpdateRequest,
    TimetableResponse,
    TimetableListResponse,
)
from app.services import timetable_service

router = APIRouter(prefix="/timetable", tags=["Timetable"])


@router.post("/", response_model=TimetableResponse, status_code=status.HTTP_201_CREATED)
def create(
    body: TimetableCreateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return timetable_service.create_timetable(db, user.id, body)


@router.get("/", response_model=TimetableListResponse)
def list_timetables(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    tts = timetable_service.get_timetables(db, user.id)
    return {"timetables": tts, "total": len(tts)}


@router.get("/{tt_id}", response_model=TimetableResponse)
def get_timetable(
    tt_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    tt = timetable_service.get_timetable(db, tt_id, user.id)
    if not tt:
        raise HTTPException(status_code=404, detail="Timetable not found")
    return tt


@router.put("/{tt_id}", response_model=TimetableResponse)
def update(
    tt_id: int,
    body: TimetableUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    tt = timetable_service.get_timetable(db, tt_id, user.id)
    if not tt:
        raise HTTPException(status_code=404, detail="Timetable not found")
    return timetable_service.update_timetable(db, tt, body)


@router.delete("/{tt_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(
    tt_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    tt = timetable_service.get_timetable(db, tt_id, user.id)
    if not tt:
        raise HTTPException(status_code=404, detail="Timetable not found")
    timetable_service.delete_timetable(db, tt)


@router.get("/{tt_id}/export")
def export(
    tt_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    tt = timetable_service.get_timetable(db, tt_id, user.id)
    if not tt:
        raise HTTPException(status_code=404, detail="Timetable not found")
    return PlainTextResponse(
        timetable_service.export_timetable(tt),
        media_type="application/json",
    )
