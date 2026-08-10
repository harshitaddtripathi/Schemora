# Schemora

Schemora is an AI-powered scholarship and government scheme discovery and verification engine designed for Indian students. It matches students with central and state schemes using deterministic eligibility verification, source-grounded RAG explanations, and intelligent document validation.

---

## Repository Architecture

```text
Schemora/
├── backend/                  # FastAPI backend service (Python 3.13 + uv)
│   ├── app/                  # Application code (API endpoints, schemas, DB models)
│   ├── alembic/              # Database migrations (SQLAlchemy 2.0)
│   └── tests/                # Automated pytest suite
├── frontend/                 # Flutter application (Android & Web)
│   ├── lib/                  # Dart source code (Riverpod, go_router, Dio)
│   └── web/                  # Web build configuration
├── data/                     # Frozen Phase 0 dataset, schemas, and fixtures
│   ├── schemas/              # JSON Schema Draft 2020-12 contracts
│   ├── schemes/              # Scheme definitions & eligibility rules
│   ├── sources/              # Verified official source documents
│   └── benchmark_profiles/   # Synthetic test profiles & baseline expected outcomes
├── scripts/                  # Dataset validation and helper scripts
└── .github/workflows/        # CI/CD workflows for testing and analysis
```

---

## Getting Started

### Prerequisites
- **Python 3.13+** and [`uv`](https://github.com/astral-sh/uv)
- **Flutter SDK 3.32+**
- **PostgreSQL 15+** (with `pgvector` extension enabled)

---

### Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Configure Environment Variables**:
   Copy `.env.example` to `.env` and configure your database string:
   ```bash
   cp ../.env.example .env
   ```

3. **Install Dependencies and Run Migrations**:
   ```bash
   uv sync
   uv run alembic upgrade head
   ```

4. **Start Development Server**:
   ```bash
   uv run uvicorn app.main:app --reload --port 8000
   ```
   Access interactive API docs at `http://localhost:8000/docs`.

---

### Frontend (Flutter) Setup

1. **Navigate to frontend directory**:
   ```bash
   cd frontend
   ```

2. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Flutter App**:
   - Web:
     ```bash
     flutter run -d chrome
     ```
   - Android:
     ```bash
     flutter run -d android
     ```

---

## Dataset & Phase 0 Validation

Validate dataset integrity and manifest hashes:
```bash
uv run --with-requirements requirements-phase0.txt python scripts/validate_phase0.py
```
