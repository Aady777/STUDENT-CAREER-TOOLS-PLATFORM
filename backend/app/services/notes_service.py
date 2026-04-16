"""
Notes service – CRUD + search for student notes.
"""

from sqlalchemy.orm import Session
from sqlalchemy import or_, cast, String
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
                cast(Note.content, String).ilike(pattern),
                Note.tags.ilike(pattern),
            )
        )
    return query.order_by(Note.updated_at.desc(), Note.created_at.desc()).all()


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
    """Export a note as formatted text."""
    lines = [
        f"TITLE: {note.title}",
        f"TAGS: {note.tags}" if note.tags else "",
        f"CREATED: {note.created_at}",
        "-" * 20,
        str(note.content),  # Content is rich JSON data
    ]
    if note.attachments:
        lines.append("\nATTACHMENTS:")
        for a in note.attachments:
            lines.append(f"  - {a.get('name')}  ({a.get('size_bytes', 0) // 1024} KB)")
    return "\n".join(lines)


def add_attachment(db: Session, note: Note, attachment_meta: dict) -> Note:
    """
    Append a new attachment metadata dict to note.attachments and save.
    SQLAlchemy needs a new list object to detect JSON column mutation.
    """
    current = list(note.attachments or [])
    current.append(attachment_meta)
    note.attachments = current          # reassign so SQLAlchemy detects change
    db.commit()
    db.refresh(note)
    return note


def remove_attachment(db: Session, note: Note, stored_name: str) -> Note:
    """
    Remove an attachment entry by its stored_name from note.attachments.
    """
    current = list(note.attachments or [])
    note.attachments = [a for a in current if a.get("stored_name") != stored_name]
    db.commit()
    db.refresh(note)
    return note
