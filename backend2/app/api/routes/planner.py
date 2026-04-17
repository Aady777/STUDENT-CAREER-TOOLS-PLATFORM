"""
Study Planner routes – full CRUD + progress.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.planner_service import (
    PlannerCreateRequest,
    PlannerUpdateRequest,
    PlannerResponse,
    PlannerListResponse,
)
from app.services import planner_service

router = APIRouter(prefix="/planner", tags=["Study Planner"])


@router.post("/", response_model=PlannerResponse, status_code=status.HTTP_201_CREATED)
def create(
    body: PlannerCreateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return planner_service.create_task(db, user.id, body)


@router.get("/", response_model=PlannerListResponse)
def list_tasks(
    completed: bool | None = Query(default=None),
    priority: str | None = Query(default=None),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    tasks = planner_service.get_tasks(db, user.id, completed, priority)
    progress = planner_service.get_progress(db, user.id)
    return {"tasks": tasks, "total": progress["total"], "completed": progress["completed"]}


@router.get("/progress")
def progress(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return planner_service.get_progress(db, user.id)


@router.get("/{task_id}", response_model=PlannerResponse)
def get_task(
    task_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task = planner_service.get_task(db, task_id, user.id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.put("/{task_id}", response_model=PlannerResponse)
def update(
    task_id: int,
    body: PlannerUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task = planner_service.get_task(db, task_id, user.id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return planner_service.update_task(db, task, body)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(
    task_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task = planner_service.get_task(db, task_id, user.id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    planner_service.delete_task(db, task)
