"""
Tests for CGPA calculation logic and API endpoints.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.core.dependencies import get_db
from app.main import app
from app.services.cgpa_service import calculate_cgpa
from app.utils.grade_utils import grade_to_point

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


# ── Helper ───────────────────────────────────────────────
def _register_and_login() -> str:
    """Register a test user and return auth header token."""
    email = f"cgpa_test_{id(object())}@test.com"
    client.post("/api/auth/register", json={"email": email, "password": "testpass123"})
    resp = client.post("/api/auth/login", data={"username": email, "password": "testpass123"})
    token = resp.json()["access_token"]
    return token


# ── Unit tests ───────────────────────────────────────────
class TestGradeUtils:
    def test_valid_grades(self):
        assert grade_to_point("O") == 10.0
        assert grade_to_point("A+") == 9.0
        assert grade_to_point("B") == 6.0
        assert grade_to_point("F") == 0.0

    def test_case_insensitive(self):
        assert grade_to_point("a+") == 9.0
        assert grade_to_point("o") == 10.0

    def test_numeric_input(self):
        assert grade_to_point("8.5") == 8.5

    def test_invalid_grade(self):
        with pytest.raises(ValueError):
            grade_to_point("Z")


class TestCGPACalculation:
    def test_basic_calculation(self):
        subjects = [
            {"subject": "Maths", "grade": "A+", "credits": 4},
            {"subject": "Physics", "grade": "A", "credits": 3},
            {"subject": "Chemistry", "grade": "B+", "credits": 3},
        ]
        result = calculate_cgpa(subjects)
        # (9*4 + 8*3 + 7*3) / (4+3+3) = (36+24+21)/10 = 81/10 = 8.1
        assert result == 8.1

    def test_empty_credits(self):
        assert calculate_cgpa([]) == 0.0


# ── API tests ────────────────────────────────────────────
class TestCGPAAPI:
    def test_calculate_endpoint(self):
        token = _register_and_login()
        resp = client.post(
            "/api/cgpa/calculate",
            json={
                "subjects": [
                    {"subject": "Maths", "grade": "A+", "credits": 4},
                    {"subject": "Physics", "grade": "A", "credits": 3},
                ]
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 201
        data = resp.json()
        assert "result" in data
        assert data["result"] > 0

    def test_history_endpoint(self):
        token = _register_and_login()
        # First create a record
        client.post(
            "/api/cgpa/calculate",
            json={"subjects": [{"subject": "CS", "grade": "O", "credits": 4}]},
            headers={"Authorization": f"Bearer {token}"},
        )
        resp = client.get("/api/cgpa/history", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code == 200
        assert resp.json()["total"] >= 1

    def test_unauthenticated(self):
        resp = client.post("/api/cgpa/calculate", json={"subjects": []})
        assert resp.status_code == 401
