"""
Study Planner service – CRUD + filtering for planner tasks.
"""

from sqlalchemy.orm import Session
from app.models.planner import Planner
from app.schemas.planner_service import PlannerCreateRequest, PlannerUpdateRequest


def create_task(db: Session, user_id: int, payload: PlannerCreateRequest) -> Planner:
    task = Planner(
        user_id=user_id,
        title=payload.title,
        description=payload.description,
        due_date=payload.due_date,
        priority=payload.priority.value,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


def get_tasks(
    db: Session,
    user_id: int,
    completed: bool | None = None,
    priority: str | None = None,
) -> list[Planner]:
    query = db.query(Planner).filter(Planner.user_id == user_id)
    if completed is not None:
        query = query.filter(Planner.is_completed == completed)
    if priority:
        query = query.filter(Planner.priority == priority)
    return query.order_by(Planner.due_date.asc().nullslast(), Planner.created_at.desc()).all()


def get_task(db: Session, task_id: int, user_id: int) -> Planner | None:
    return db.query(Planner).filter(Planner.id == task_id, Planner.user_id == user_id).first()


def update_task(db: Session, task: Planner, payload: PlannerUpdateRequest) -> Planner:
    update_data = payload.model_dump(exclude_unset=True)
    if "priority" in update_data and update_data["priority"] is not None:
        update_data["priority"] = update_data["priority"].value
    for key, value in update_data.items():
        setattr(task, key, value)
    db.commit()
    db.refresh(task)
    return task


def delete_task(db: Session, task: Planner) -> None:
    db.delete(task)
    db.commit()


def get_progress(db: Session, user_id: int) -> dict:
    """Return completion stats."""
    total = db.query(Planner).filter(Planner.user_id == user_id).count()
    completed = db.query(Planner).filter(Planner.user_id == user_id, Planner.is_completed == True).count()
    return {"total": total, "completed": completed, "pending": total - completed}
