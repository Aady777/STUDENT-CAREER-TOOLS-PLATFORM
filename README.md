# 🎓 Student & Career Tools Platform — Enterprise Backend

An enterprise-grade, scalable backend system built for modern education platforms. This system is designed to handle high-concurrency for student-centric tools including Mock Tests, Study Planning, CGPA Calculation, and Rich-Text Note-taking.

---

## 🛠 Tech Stack
- **Core Framework**: FastAPI (Asynchronous Python)
- **Primary Database**: PostgreSQL (for persisted data & history)
- **Caching & Sessions**: Redis (for test timers & cheating prevention)
- **Task Scheduling**: APScheduler (for periodic reminders & cleanup)
- **Containerization**: Docker & Docker-Compose

---

## 🚀 Getting Started (Quick Start)

The backend is fully containerized. To ensure PostgreSQL and Redis are wired correctly, **always run using Docker.**

### 1. Prerequisite
Ensure you have [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed on your machine.

### 2. Launch the Platform
```bash
docker-compose up --build
```
This command will:
- Spin up the **FastAPI API** on port `8000`.
- Initialize the **PostgreSQL 15** database.
- Start the **Redis 7** session store.
- Initialize the **Background Worker** for study task reminders.

### 3. Access API Documentation
Once the containers are running, the interactive documentation is available at:
👉 **[http://localhost:8000/docs](http://localhost:8000/docs)**

---

## 🏗 Key Features for Integration

### 1. Mock Test Session Flow (Active Security)
To prevent cheating, tests use a two-step session flow:
- **START**: Call `POST /api/tests/{id}/start`. You will receive a `session_token` and an `expiry_time`.
- **SUBMIT**: Call `POST /api/tests/submit` and include the `session_token`.
- **Note**: Submissions will return **HTTP 408** if the Redis timer has expired.

### 2. Rich-Text Notes & Attachments
- **Content**: Notes use a JSON-based content field compatible with **Editor.js** or **Draft.js**.
- **Uploads**: Use `POST /api/notes/{id}/attachments` (Multipart/form-data). Files are served statically under `/uploads`.

### 3. Study Planner & Automations
- Tasks are persisted in Postgres. 
- The **Background Worker** automatically logs reminders for tasks due today. (Ready for Email/Push integration).

### 4. CGPA Calculator
- Sophisticated engine converts grades to points and calculates weighted results.
- Full history stored for every student attempt.

---

## 📂 Project Structure
```text
backend/
├── app/
│   ├── api/          # Endpoints & Router mounting
│   ├── core/         # DB Pooling, Redis config, Security logic
│   ├── models/       # SQLAlchemy database schemas
│   ├── services/     # Core business logic (Analytics, Evaluation, etc.)
│   ├── schemas/      # Pydantic validation (Input/Output data types)
│   └── workers/      # Background task implementations
├── tests/            # Integration & Logic verification tests
└── docker-compose.yml
```

---

## 📡 Deployment & Variables
Configure the `.env` file before deployment:
- `DATABASE_URL`: PostgreSQL connection string.
- `REDIS_URL`: Redis connection string.
- `SECRET_KEY`: JWT signing secret.
- `DB_POOL_SIZE`: Default is 10 connections.

---

##  Contribution for Frontend
When integrating, always refer to the `/docs` endpoint. Every router is tagged by feature (Auth, CGPA, Planner, etc.) with detailed request/response examples.
