"""
Storage Service – local file system storage for note attachments.

Files are saved to:  /app/uploads/{user_id}/{note_id}/{uuid}_{filename}

Structure:
  uploads/
  └── {user_id}/
      └── {note_id}/
          ├── a1b2c3_lecture.pdf
          └── d4e5f6_diagram.png

Security rules enforced here:
  - Allowed mime types: PDF, PNG, JPG, JPEG, WEBP, GIF, TXT
  - Max file size: 10 MB
  - Filename sanitised (no path traversal)
"""

import uuid
import logging
import mimetypes
from pathlib import Path

import aiofiles

logger = logging.getLogger(__name__)

# ── Config ────────────────────────────────────────────────
UPLOAD_ROOT = Path("/app/uploads")          # Docker volume mount path
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024      # 10 MB

ALLOWED_MIME_TYPES = {
    "application/pdf",
    "image/png",
    "image/jpeg",
    "image/webp",
    "image/gif",
    "text/plain",
}

ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg", ".webp", ".gif", ".txt"}


# ── Helpers ───────────────────────────────────────────────

def _sanitise_filename(filename: str) -> str:
    """
    Strip path separators and dangerous characters.
    Only keep the base name — no directories allowed.
    """
    return Path(filename).name.replace(" ", "_")


def _get_upload_dir(user_id: int, note_id: int) -> Path:
    """Return (and create) the user/note-specific upload directory."""
    directory = UPLOAD_ROOT / str(user_id) / str(note_id)
    directory.mkdir(parents=True, exist_ok=True)
    return directory


def _validate_file(filename: str, content_type: str, size: int) -> None:
    """
    Raise ValueError if the file fails any validation check.
    """
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(
            f"File type '{ext}' not allowed. "
            f"Allowed: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
        )

    if content_type not in ALLOWED_MIME_TYPES:
        raise ValueError(
            f"MIME type '{content_type}' not allowed. "
            f"Allowed: {', '.join(sorted(ALLOWED_MIME_TYPES))}"
        )

    if size > MAX_FILE_SIZE_BYTES:
        raise ValueError(
            f"File too large ({size / 1024 / 1024:.1f} MB). "
            f"Max allowed: {MAX_FILE_SIZE_BYTES // 1024 // 1024} MB."
        )


# ── Core operations ───────────────────────────────────────

async def save_file(
    user_id: int,
    note_id: int,
    filename: str,
    content_type: str,
    data: bytes,
) -> dict:
    """
    Validate and persist a file to local storage.

    Returns a dict with metadata:
        { name, url, size, mime_type }
    """
    safe_name = _sanitise_filename(filename)
    size = len(data)

    # ── Validate ──────────────────────────────────────────
    _validate_file(safe_name, content_type, size)

    # ── Build unique path ──────────────────────────────────
    unique_prefix = uuid.uuid4().hex[:8]
    stored_name = f"{unique_prefix}_{safe_name}"
    upload_dir = _get_upload_dir(user_id, note_id)
    file_path = upload_dir / stored_name

    # ── Write async ───────────────────────────────────────
    async with aiofiles.open(file_path, "wb") as f:
        await f.write(data)

    logger.info(
        "File saved | user=%s | note=%s | file=%s | size=%d bytes",
        user_id, note_id, stored_name, size,
    )

    # ── Return metadata (stored in Note.attachments JSON) ─
    return {
        "name": safe_name,
        "stored_name": stored_name,
        "url": f"/uploads/{user_id}/{note_id}/{stored_name}",
        "size_bytes": size,
        "mime_type": content_type,
    }


def delete_file(user_id: int, note_id: int, stored_name: str) -> bool:
    """
    Delete a specific file from storage.
    Returns True if deleted, False if file didn't exist.
    """
    file_path = UPLOAD_ROOT / str(user_id) / str(note_id) / stored_name
    if file_path.exists():
        file_path.unlink()
        logger.info("File deleted | path=%s", file_path)
        return True
    logger.warning("File not found for deletion | path=%s", file_path)
    return False


def delete_all_note_files(user_id: int, note_id: int) -> None:
    """
    Delete the entire folder for a note (called when note is deleted).
    """
    note_dir = UPLOAD_ROOT / str(user_id) / str(note_id)
    if note_dir.exists():
        import shutil
        shutil.rmtree(note_dir)
        logger.info("All files deleted for note | user=%s | note=%s", user_id, note_id)
