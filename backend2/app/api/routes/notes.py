"""
Notes routes – CRUD + search + export.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import PlainTextResponse
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.notes_service import (
    NoteCreateRequest,
    NoteUpdateRequest,
    NoteResponse,
    NoteListResponse,
)
from app.services import notes_service

router = APIRouter(prefix="/notes", tags=["Notes"])


@router.post("/", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
def create(
    body: NoteCreateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return notes_service.create_note(db, user.id, body)


@router.get("/", response_model=NoteListResponse)
def list_notes(
    search: str | None = Query(default=None, description="Search in title, content, or tags"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    notes = notes_service.get_notes(db, user.id, search)
    return {"notes": notes, "total": len(notes)}


@router.get("/{note_id}", response_model=NoteResponse)
def get_note(
    note_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    note = notes_service.get_note(db, note_id, user.id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return note


@router.put("/{note_id}", response_model=NoteResponse)
def update(
    note_id: int,
    body: NoteUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    note = notes_service.get_note(db, note_id, user.id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return notes_service.update_note(db, note, body)


@router.delete("/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(
    note_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    note = notes_service.get_note(db, note_id, user.id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    notes_service.delete_note(db, note)


@router.get("/{note_id}/export")
def export(
    note_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    note = notes_service.get_note(db, note_id, user.id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return PlainTextResponse(notes_service.export_note(note))
