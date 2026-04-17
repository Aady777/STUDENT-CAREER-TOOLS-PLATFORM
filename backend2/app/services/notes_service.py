"""
Notes service – CRUD + search for student notes.
"""

from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models.notes import Note
from app.schemas.notes_service import NoteCreateRequest, NoteUpdateRequest


def create_note(db: Session, user_id: int, payload: NoteCreateRequest) -> Note:
    note = Note(
        user_id=user_id,
        title=payload.title,
        content=payload.content,
        tags=payload.tags,
    )
    db.add(note)
    db.commit()
    db.refresh(note)
    return note


def get_notes(db: Session, user_id: int, search: str | None = None) -> list[Note]:
    query = db.query(Note).filter(Note.user_id == user_id)
    if search:
        pattern = f"%{search}%"
        query = query.filter(
            or_(
                Note.title.ilike(pattern),
                Note.content.ilike(pattern),
                Note.tags.ilike(pattern),
            )
        )
    return query.order_by(Note.updated_at.desc().nullslast(), Note.created_at.desc()).all()


def get_note(db: Session, note_id: int, user_id: int) -> Note | None:
    return db.query(Note).filter(Note.id == note_id, Note.user_id == user_id).first()


def update_note(db: Session, note: Note, payload: NoteUpdateRequest) -> Note:
    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(note, key, value)
    db.commit()
    db.refresh(note)
    return note


def delete_note(db: Session, note: Note) -> None:
    db.delete(note)
    db.commit()


def export_note(note: Note) -> str:
    """Export a note as formatted plain text."""
    lines = [
        f"# {note.title}",
        f"Tags: {note.tags}" if note.tags else "",
        f"Created: {note.created_at}",
        "",
        note.content,
    ]
    return "\n".join(lines)
