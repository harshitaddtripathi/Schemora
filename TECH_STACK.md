# Schemora - Technology Stack

Last reviewed: August 7, 2026

This stack is designed for a two-developer, three-day academic MVP with an Android citizen application, web admin dashboard, deterministic eligibility rules, RAG, and OCR.

## Architecture

```text
Flutter Android App ----+
                        +--> FastAPI on Render
Flutter Web Admin ------+       |
                                +--> Supabase PostgreSQL + pgvector
                                +--> Supabase Storage
                                +--> Gemini API

Flutter App --> Firebase Authentication --> FastAPI token verification
```

All database, storage, eligibility, and AI operations pass through FastAPI. Flutter must not connect directly to PostgreSQL or contain privileged service credentials.

## Stack

| Area | Technology |
| --- | --- |
| Citizen application | Flutter and Dart |
| Admin dashboard | Flutter Web |
| State management | Riverpod |
| Navigation | `go_router` |
| HTTP client | Dio |
| Dart models | Freezed and `json_serializable` |
| Public offline cache | Drift with SQLite |
| Local reminders | `flutter_local_notifications` |
| Authentication | Firebase Phone Authentication |
| Backend | Python 3.13 and FastAPI |
| Validation | Pydantic |
| ORM and migrations | SQLAlchemy 2 and Alembic |
| PostgreSQL driver | Psycopg 3 |
| Database | Supabase PostgreSQL |
| Vector storage | pgvector |
| Document storage | Private Supabase Storage |
| AI SDK | `google-genai` |
| Generation model | Gemini 3.6 Flash |
| Embedding model | `gemini-embedding-2`, 768 dimensions |
| AI orchestration | LangGraph |
| Mobile OCR | Google ML Kit Text Recognition |
| PDF extraction | PyMuPDF with Tesseract fallback |
| Backend hosting | Render |
| CI | GitHub Actions |
| Monitoring | Firebase Crashlytics and structured backend logs |

## Flutter

Use one Flutter project for the Android citizen application and web admin dashboard. Share the API client, models, theme, validation, and common widgets.

Recommended packages:

```text
flutter_riverpod
go_router
dio
freezed
json_serializable
firebase_core
firebase_auth
drift
flutter_local_notifications
url_launcher
image_picker
file_picker
google_mlkit_text_recognition
firebase_crashlytics
```

Use a feature-first structure:

```text
lib/
  app/
  core/
  features/
    authentication/
    profile/
    schemes/
    recommendations/
    documents/
    checklist/
    reminders/
    assistant/
    admin/
```

## FastAPI

Recommended packages:

```text
fastapi
uvicorn[standard]
pydantic-settings
sqlalchemy
alembic
psycopg[binary,pool]
pgvector
firebase-admin
google-genai
langgraph
supabase
httpx
python-multipart
pymupdf
pytesseract
structlog
pytest
pytest-asyncio
```

FastAPI is responsible for:

- Verifying Firebase ID tokens and roles
- Managing profiles, schemes, documents, and reminders
- Running deterministic eligibility and ranking logic
- Retrieving approved RAG sources
- Calling Gemini and validating structured output
- Generating signed Supabase Storage URLs
- Enforcing document ownership

## Data and Storage

Core PostgreSQL tables:

```text
users
student_profiles
schemes
scheme_sources
eligibility_rules
scheme_required_documents
application_windows
knowledge_documents
knowledge_chunks
document_metadata
saved_schemes
reminders
analytics_events
```

Use UUID keys, UTC timestamps, validated JSON eligibility rules, versioned scheme records, and embeddings only for administrator-approved content.

Store document metadata in PostgreSQL and files in private Supabase Storage buckets. Use short-lived signed URLs and user ownership checks.

## Eligibility and AI

Eligibility must be calculated by deterministic Python code. Gemini may explain results but must not change them.

```text
Profile
  -> deterministic eligibility
  -> approved-source retrieval
  -> Gemini explanation or checklist
  -> citation and schema validation
```

LangGraph should coordinate this fixed workflow. Do not use autonomous agent loops.

AI answers must:

- Use only published knowledge-base content
- Include official citations and last-verified dates
- Return the approved fallback response when evidence is insufficient
- Never provide official eligibility, legal advice, or financial advice

## OCR and Privacy

Use Google ML Kit for Aadhaar, PAN, and Income Certificate text recognition. Use PyMuPDF for government PDFs and Tesseract only for scanned PDF pages.

- Retain only masked Aadhaar and PAN values
- Never log full identifiers or document content
- Use synthetic or redacted documents for evaluation
- Upload documents only when the user chooses saved storage
- Delete temporary and failed processing files

## Authentication and Secrets

Citizens authenticate with Firebase Phone OTP. FastAPI verifies Firebase ID tokens and maps the Firebase UID to an application user.

Administrators use email, password, OTP, and a manually assigned database role.

Keep these values only in backend environment variables:

```text
DATABASE_URL
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
GEMINI_API_KEY
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
```

Never place service-role keys, database credentials, or Gemini keys in Flutter code or Git.

## Deployment and Testing

- Deploy FastAPI to Render with Python 3.13 pinned.
- Use Supabase for PostgreSQL, pgvector, and private file storage.
- Use Firebase for Phone Authentication and Crashlytics.
- Warm the Render service before evaluation if using a sleeping free instance.
- Commit dependency lockfiles and an `.env.example`.

GitHub Actions should run:

```text
Backend: lint, type checks, pytest
Flutter: format check, analyze, test, APK build, web build
```

Prioritize tests for eligibility rules, recommendation ranking, missing values, permissions, document masking, citations, profile forms, error states, and the final citizen/admin demonstration flows.

## Repository Layout

```text
schemora/
  frontend/
  backend/
  data/
    schemes/
    sources/
    benchmark_profiles/
    synthetic_documents/
  docs/
  .github/workflows/
  PROJECT_SCOPE.md
  TECH_STACK.md
  README.md
```

## Excluded From the MVP

- Microservices and Kubernetes
- Redis, Celery, and Kafka
- A separate vector database
- A separate React or Next.js admin application
- Direct Flutter-to-database access
- LLM-based eligibility decisions
- Autonomous multi-agent loops
- Raw identity-document submission to Gemini
