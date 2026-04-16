"""
CGPA routes – calculate, history, delete.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.cgpa_service import CGPACalculateRequest, CGPAResponse, CGPAHistoryResponse
from app.services import cgpa_service

router = APIRouter(prefix="/cgpa", tags=["CGPA Calculator"])


@router.post("/calculate", response_model=CGPAResponse, status_code=status.HTTP_201_CREATED)
def calculate(
    body: CGPACalculateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Calculate CGPA from subjects + grades and store the result."""
    record = cgpa_service.create_cgpa_record(db, user, body)
    return record


@router.get("/history", response_model=CGPAHistoryResponse)
def history(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Get all past CGPA calculations for the current user."""
    records = cgpa_service.get_cgpa_history(db, user.id)
    return {"records": records, "total": len(records)}


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(
    record_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Delete a CGPA record."""
    if not cgpa_service.delete_cgpa_record(db, record_id, user.id):
        raise HTTPException(status_code=404, detail="Record not found")
