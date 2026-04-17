"""
Integration tests for the Mock Test Flow.

Covers the complete lifecycle:
  1. Create a test        POST /tests/
  2. Start a session      POST /tests/{id}/start
  3. Check remaining time GET  /tests/{id}/time
  4. Submit (valid)        POST /tests/submit       → 201 + result with topic_breakdown
  5. Submit (expired)      POST /tests/submit       → 408 (session expired)
  6. Submit (bad token)    POST /tests/submit       → 408 (token mismatch)
  7. Submit (no auth)      POST /tests/submit       → 401
  8. Results history       GET  /tests/results/me

Database: PostgreSQL (run inside Docker via docker-compose exec api pytest)
Redis:    Mocked via unittest.mock — no live Redis needed for the test logic.

Run:  docker-compose exec api pytest tests/test_test_flow.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

from app.main import app
from app.core.redis import get_redis

# ── Mock Redis client ─────────────────────────────────────
# Avoids any dependency on a live Redis server during test collection.
mock_redis = MagicMock()
mock_redis.ping.return_value = True

app.dependency_overrides[get_redis] = lambda: mock_redis

client = TestClient(app, raise_server_exceptions=False)


# ── Helpers ──────────────────────────────────────────────
def _register_and_login(suffix: str = "") -> str:
    """Create a unique user and return Bearer token."""
    email = f"testflow{suffix}_{id(object())}@test.com"
    client.post("/api/auth/register", json={"email": email, "password": "pass1234"})
    resp = client.post("/api/auth/login", data={"username": email, "password": "pass1234"})
    return resp.json()["access_token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


SAMPLE_TEST = {
    "title": "Physics Unit 1",
    "subject": "Physics",
    "duration_minutes": 30,
    "questions": [
        {
            "question": "Speed of light?",
            "options": ["3e8", "3e6", "3e10", "3e5"],
            "correct": 0,
            "topic": "Optics",
        },
        {
            "question": "SI unit of force?",
            "options": ["Watt", "Newton", "Joule", "Pascal"],
            "correct": 1,
            "topic": "Mechanics",
        },
        {
            "question": "Ohm's law?",
            "options": ["V=IR", "V=I/R", "V=I+R", "V=I-R"],
            "correct": 0,
            "topic": "Electricity",
        },
    ],
}


# ── Test classes ─────────────────────────────────────────
class TestTestCRUD:
    """Test creation and retrieval of test papers."""

    def test_create_test_authenticated(self):
        token = _register_and_login("crud")
        resp = client.post("/api/tests/", json=SAMPLE_TEST, headers=_auth(token))
        assert resp.status_code == 201
        data = resp.json()
        assert data["title"] == "Physics Unit 1"
        assert data["subject"] == "Physics"
        assert len(data["questions"]) == 3

    def test_create_test_unauthenticated(self):
        resp = client.post("/api/tests/", json=SAMPLE_TEST)
        assert resp.status_code == 401

    def test_list_tests(self):
        token = _register_and_login("list")
        client.post("/api/tests/", json=SAMPLE_TEST, headers=_auth(token))
        resp = client.get("/api/tests/", headers=_auth(token))
        assert resp.status_code == 200
        assert resp.json()["total"] >= 1

    def test_get_nonexistent_test(self):
        token = _register_and_login("missing")
        resp = client.get("/api/tests/99999", headers=_auth(token))
        assert resp.status_code == 404


class TestSessionFlow:
    """Test Redis-backed session start and time-remaining endpoints."""

    def setup_method(self):
        self.token = _register_and_login("session")
        resp = client.post("/api/tests/", json=SAMPLE_TEST, headers=_auth(self.token))
        self.test_id = resp.json()["id"]

    def test_start_session_returns_token(self):
        mock_redis.setex.return_value = True
        resp = client.post(
            f"/api/tests/{self.test_id}/start", headers=_auth(self.token)
        )
        assert resp.status_code == 201
        data = resp.json()
        assert "session_token" in data
        assert data["test_id"] == self.test_id
        assert data["duration_minutes"] == 30
        assert data["expires_in_seconds"] == 1800

    def test_start_nonexistent_test(self):
        resp = client.post("/api/tests/99999/start", headers=_auth(self.token))
        assert resp.status_code == 404

    def test_time_remaining_active(self):
        mock_redis.setex.return_value = True
        mock_redis.ttl.return_value = 1750
        client.post(f"/api/tests/{self.test_id}/start", headers=_auth(self.token))
        resp = client.get(f"/api/tests/{self.test_id}/time", headers=_auth(self.token))
        assert resp.status_code == 200
        data = resp.json()
        assert data["test_id"] == self.test_id
        assert "remaining_seconds" in data

    def test_time_remaining_no_session(self):
        mock_redis.ttl.return_value = -2  # key doesn't exist in Redis
        resp = client.get(f"/api/tests/{self.test_id}/time", headers=_auth(self.token))
        assert resp.status_code == 200
        assert resp.json()["active"] is False
        assert resp.json()["remaining_seconds"] == 0


class TestSubmitFlow:
    """Test answer submission under various session states."""

    def setup_method(self):
        self.token = _register_and_login("submit")
        resp = client.post("/api/tests/", json=SAMPLE_TEST, headers=_auth(self.token))
        self.test_id = resp.json()["id"]
        self.valid_token = "valid-session-token-abc123"

    def test_submit_correct_answers(self):
        """All correct → 100% score, topic_breakdown populated."""
        mock_redis.get.return_value = self.valid_token
        mock_redis.delete.return_value = 1

        resp = client.post(
            "/api/tests/submit",
            json={
                "test_id": self.test_id,
                "session_token": self.valid_token,
                "answers": [0, 1, 0],
                "time_taken_seconds": 300,
            },
            headers=_auth(self.token),
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["score"] == 100.0
        assert data["correct_answers"] == 3
        assert data["total_questions"] == 3
        assert "Optics" in data["topic_breakdown"]
        assert "Mechanics" in data["topic_breakdown"]
        assert "Electricity" in data["topic_breakdown"]

    def test_submit_partial_score(self):
        """Only first answer correct → ~33.33%."""
        mock_redis.get.return_value = self.valid_token
        mock_redis.delete.return_value = 1

        resp = client.post(
            "/api/tests/submit",
            json={
                "test_id": self.test_id,
                "session_token": self.valid_token,
                "answers": [0, 0, 0],
                "time_taken_seconds": 450,
            },
            headers=_auth(self.token),
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["score"] == pytest.approx(33.33, abs=0.1)
        assert data["correct_answers"] == 1

    def test_submit_expired_session_returns_408(self):
        """Redis returns None → session expired → 408."""
        mock_redis.get.return_value = None

        resp = client.post(
            "/api/tests/submit",
            json={
                "test_id": self.test_id,
                "session_token": "expired-token",
                "answers": [0, 1, 0],
            },
            headers=_auth(self.token),
        )
        assert resp.status_code == 408
        assert "expired" in resp.json()["detail"].lower()

    def test_submit_invalid_token_returns_408(self):
        """Token mismatch → submission rejected → 408."""
        mock_redis.get.return_value = "different-stored-token"

        resp = client.post(
            "/api/tests/submit",
            json={
                "test_id": self.test_id,
                "session_token": "forged-token",
                "answers": [0, 1, 0],
            },
            headers=_auth(self.token),
        )
        assert resp.status_code == 408
        assert "invalid" in resp.json()["detail"].lower()

    def test_submit_nonexistent_test(self):
        mock_redis.get.return_value = self.valid_token

        resp = client.post(
            "/api/tests/submit",
            json={
                "test_id": 99999,
                "session_token": self.valid_token,
                "answers": [0],
            },
            headers=_auth(self.token),
        )
        assert resp.status_code == 404

    def test_submit_unauthenticated(self):
        resp = client.post(
            "/api/tests/submit",
            json={
                "test_id": self.test_id,
                "session_token": self.valid_token,
                "answers": [0, 1, 0],
            },
        )
        assert resp.status_code == 401


class TestResults:
    """Test result history retrieval after submission."""

    def setup_method(self):
        self.token = _register_and_login("results")
        resp = client.post("/api/tests/", json=SAMPLE_TEST, headers=_auth(self.token))
        self.test_id = resp.json()["id"]

    def test_my_results_empty_initially(self):
        resp = client.get("/api/tests/results/me", headers=_auth(self.token))
        assert resp.status_code == 200
        assert resp.json()["total"] == 0

    def test_my_results_after_submission(self):
        tok = "result-history-token"
        mock_redis.get.return_value = tok
        mock_redis.delete.return_value = 1

        client.post(
            "/api/tests/submit",
            json={"test_id": self.test_id, "session_token": tok, "answers": [0, 1, 0]},
            headers=_auth(self.token),
        )

        resp = client.get("/api/tests/results/me", headers=_auth(self.token))
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] >= 1
        assert data["results"][0]["score"] == 100.0

    def test_results_unauthenticated(self):
        resp = client.get("/api/tests/results/me")
        assert resp.status_code == 401


class TestErrorHandlers:
    """Verify the global error handler returns the standardised JSON envelope."""

    def test_404_structured_body(self):
        token = _register_and_login("err404")
        resp = client.get("/api/tests/99999", headers=_auth(token))
        assert resp.status_code == 404
        body = resp.json()
        assert "error" in body
        assert "detail" in body
        assert "status" in body
        assert body["status"] == 404

    def test_401_structured_body(self):
        resp = client.get("/api/tests/")
        assert resp.status_code == 401
        body = resp.json()
        assert "error" in body
        assert body["status"] == 401
