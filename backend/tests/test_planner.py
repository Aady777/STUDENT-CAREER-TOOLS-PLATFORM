"""
Tests for Study Planner API endpoints.
"""

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.core.dependencies import get_db
from app.main import app

# ── In-memory test DB ────────────────────────────────────
TEST_DB_URL = "sqlite:///./test_student.db"
engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestSession = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)


def override_get_db():
    db = TestSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


def _register_and_login() -> str:
    email = f"planner_test_{id(object())}@test.com"
    client.post("/api/auth/register", json={"email": email, "password": "testpass123"})
    resp = client.post("/api/auth/login", data={"username": email, "password": "testpass123"})
    return resp.json()["access_token"]


class TestPlannerAPI:
    def test_create_task(self):
        token = _register_and_login()
        resp = client.post(
            "/api/planner/",
            json={
                "title": "Study Linear Algebra",
                "description": "Chapters 3 and 4",
                "priority": "high",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["title"] == "Study Linear Algebra"
        assert data["priority"] == "high"
        assert data["is_completed"] is False

    def test_list_tasks(self):
        token = _register_and_login()
        # Create two tasks
        for title in ["Task A", "Task B"]:
            client.post(
                "/api/planner/",
                json={"title": title},
                headers={"Authorization": f"Bearer {token}"},
            )
        resp = client.get("/api/planner/", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code == 200
        assert resp.json()["total"] >= 2

    def test_update_task_completion(self):
        token = _register_and_login()
        create_resp = client.post(
            "/api/planner/",
            json={"title": "Complete Assignment"},
            headers={"Authorization": f"Bearer {token}"},
        )
        task_id = create_resp.json()["id"]
        update_resp = client.put(
            f"/api/planner/{task_id}",
            json={"is_completed": True},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert update_resp.status_code == 200
        assert update_resp.json()["is_completed"] is True

    def test_delete_task(self):
        token = _register_and_login()
        create_resp = client.post(
            "/api/planner/",
            json={"title": "Temporary Task"},
            headers={"Authorization": f"Bearer {token}"},
        )
        task_id = create_resp.json()["id"]
        del_resp = client.delete(
            f"/api/planner/{task_id}",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert del_resp.status_code == 204

    def test_progress(self):
        token = _register_and_login()
        client.post(
            "/api/planner/",
            json={"title": "Progress task"},
            headers={"Authorization": f"Bearer {token}"},
        )
        resp = client.get("/api/planner/progress", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code == 200
        data = resp.json()
        assert "total" in data
        assert "completed" in data
        assert "pending" in data
