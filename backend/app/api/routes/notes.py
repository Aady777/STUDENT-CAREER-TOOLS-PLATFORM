"""
Notes routes – CRUD + search + export + file attachments.

New endpoints:
  POST /notes/{note_id}/attachments          → upload a file to a note
  DELETE /notes/{note_id}/attachments/{name} → remove a file from a note
  GET  /notes/{note_id}/export               → export note as plain text
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from fastapi.responses import PlainTextResponse
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.notes_service import (
    NoteCreateRequest,
    NoteUpdateRequest,
    NoteResponse,
    NoteListResponse,
    AttachmentResponse,
)
from app.services import notes_service, storage_service

router = APIRouter(prefix="/notes", tags=["Notes"])


# ── CRUD ─────────────────────────────────────────────────
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
    # Delete all attached files from disk before removing the DB record
    storage_service.delete_all_note_files(user.id, note_id)
    notes_service.delete_note(db, note)


# ── Export ────────────────────────────────────────────────
@router.get("/{note_id}/export", response_class=PlainTextResponse)
def export(
    note_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    note = notes_service.get_note(db, note_id, user.id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return notes_service.export_note(note)


# ── File Attachments ──────────────────────────────────────
@router.post(
    "/{note_id}/attachments",
    response_model=AttachmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a file attachment to a note",
)
async def upload_attachment(
    note_id: int,
    file: UploadFile = File(..., description="PDF, PNG, JPG, WEBP, GIF or TXT — max 10 MB"),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Uploads a file and attaches its metadata to the note.
    The file is saved to:  /app/uploads/{user_id}/{note_id}/{uuid}_{filename}
    """
    note = notes_service.get_note(db, note_id, user.id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")

    # Read bytes from the uploaded file
    data = await file.read()

    try:
        attachment_meta = await storage_service.save_file(
            user_id=user.id,
            note_id=note_id,
            filename=file.filename or "upload",
            content_type=file.content_type or "application/octet-stream",
            data=data,
        )
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

    # Persist attachment metadata into note.attachments JSON column
    notes_service.add_attachment(db, note, attachment_meta)

    return AttachmentResponse(**attachment_meta)


@router.delete(
    "/{note_id}/attachments/{stored_name}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove a file attachment from a note",
)
def delete_attachment(
    note_id: int,
    stored_name: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Deletes the file from disk and removes its entry from note.attachments.
    stored_name is the uuid-prefixed filename returned by upload.
    """
    note = notes_service.get_note(db, note_id, user.id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")

    deleted = storage_service.delete_file(user.id, note_id, stored_name)
    if not deleted:
        raise HTTPException(status_code=404, detail="Attachment file not found on disk")

    notes_service.remove_attachment(db, note, stored_name)
