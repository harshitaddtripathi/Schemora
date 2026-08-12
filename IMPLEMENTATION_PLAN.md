# Schemora - Implementation Plan

Last reviewed: August 7, 2026

This plan breaks the Schemora academic MVP into small, dependency-aware tasks for two developers over three development days.

The schedule uses relative days because the project start date has not been specified.

## Priority Labels

- `P0`: Required for the final evaluation workflow
- `P1`: Required by the MVP scope but can follow the core workflow
- `P2`: Optional polish or fallback work

## Team Split

- `Developer 1`: Backend, database, eligibility engine, RAG, deployment
- `Developer 2`: Flutter citizen app, Flutter Web admin, OCR, local features
- `Both`: Dataset validation, API contracts, integration, testing, demonstration

The split is a default, not a strict ownership boundary. Each phase ends with an integrated vertical slice.

## Critical Path

```text
Freeze scheme data
  -> database and API contracts
  -> authentication and profile
  -> eligibility and ranking
  -> source retrieval and AI explanation
  -> OCR and checklist
  -> reminders, status, and portal redirect
  -> admin publication workflow
  -> deployment and evaluation testing
```

## Phase Overview

| Phase                          | Target Window  | Main Outcome                                     |
| ------------------------------ | -------------- | ------------------------------------------------ |
| 0. Prerequisites               | Before Day 1   | Frozen data, test fixtures, and cloud access     |
| 1. Foundation                  | Day 1 morning  | Runnable Flutter and FastAPI projects            |
| 2. Authentication and Profile  | Day 1          | Authenticated student profile flow               |
| 3. Schemes and Eligibility     | Day 1 to Day 2 | Search, deterministic matching, and Top 3        |
| 4. RAG and AI Assistant        | Day 2          | Cited explanations, guidance, and chat           |
| 5. Documents and Checklist     | Day 2          | OCR, consistency analysis, and readiness         |
| 6. Citizen Completion Features | Day 2 to Day 3 | Reminders, statuses, links, cache, language      |
| 7. Admin Dashboard             | Day 3          | Scheme and knowledge publication workflow        |
| 8. Reliability and Validation  | Day 3          | Failure handling, metrics, and regression checks |
| 9. Deployment and Delivery     | Day 3          | Hosted API, APK, admin build, and demo package   |

---

## Phase 0 - Prerequisites

Complete this phase before the three-day implementation clock begins.

### Product and Data

- [ ] `P0-001` Name and freeze the exact 25 validated schemes. Owner: Both
- [ ] `P0-002` Assign a stable scheme ID to every scheme. Owner: Developer 1
- [ ] `P0-003` Record jurisdiction, state, department, category, benefits, status, and deadline type. Owner: Both
- [ ] `P0-004` Record official information and application URLs. Owner: Both
- [ ] `P0-005` Download and organize the official source documents. Owner: Both
- [ ] `P0-006` Record publication, retrieval, and last-verified dates for each source. Owner: Both
- [ ] `P0-007` Normalize mandatory and advisory eligibility conditions. Owner: Developer 1
- [ ] `P0-008` Map required documents and application steps to every validated scheme. Owner: Both
- [ ] `P0-009` Mark any additional records as search-only. Owner: Developer 1
- [ ] `P0-010` Store the frozen dataset under `data/schemes/`. Owner: Developer 1

### Benchmark Fixtures

- [ ] `P0-011` Create representative synthetic student profiles. Owner: Both
- [ ] `P0-012` Approve the expected Top 3 results for each profile. Owner: Both
- [ ] `P0-013` Approve expected satisfied, failed, and unresolved rule outcomes. Owner: Developer 1
- [ ] `P0-014` Approve expected document checklists. Owner: Both
- [ ] `P0-015` Create synthetic Aadhaar, PAN, and Income Certificate files. Owner: Developer 2
- [ ] `P0-016` Store benchmark files under `data/benchmark_profiles/`. Owner: Developer 1
- [ ] `P0-017` Store synthetic documents under `data/synthetic_documents/`. Owner: Developer 2

### Technical Decisions and Access

- [ ] `P0-018` Freeze the eligibility-rule JSON schema. Owner: Developer 1
- [ ] `P0-019` Freeze confidence and ranking weights. Owner: Both
- [ ] `P0-020` Confirm Google ML Kit as the mobile OCR engine. Owner: Developer 2
- [ ] `P0-021` Create Firebase, Supabase, Gemini, and Render projects. Owner: Both
- [ ] `P0-022` Configure Firebase test phone numbers. Owner: Developer 2
- [ ] `P0-023` Enable pgvector in Supabase PostgreSQL. Owner: Developer 1
- [ ] `P0-024` Create private Supabase Storage buckets. Owner: Developer 1
- [ ] `P0-025` Assign credential ownership and prepare safe environment values. Owner: Both

### Phase Exit Criteria

- The exact scheme inventory and benchmark results are frozen.
- Every required cloud account is accessible.
- No feature work depends on an unresolved data format.

---

## Phase 1 - Project Foundation

Target: Day 1 morning

### Repository

- [ ] `P0-101` Create `frontend/`, `backend/`, `data/`, and `.github/workflows/`. Owner: Both
- [ ] `P0-102` Add root `README.md` with setup commands. Owner: Both
- [ ] `P0-103` Add `.gitignore` rules for Flutter, Python, secrets, and generated files. Owner: Both
- [ ] `P0-104` Add root and service-level `.env.example` files. Owner: Developer 1

### Backend Foundation

- [ ] `P0-105` Initialize Python 3.13 and `uv`. Owner: Developer 1
- [ ] `P0-106` Create the FastAPI application and `/health` endpoint. Owner: Developer 1
- [ ] `P0-107` Add environment configuration with `pydantic-settings`. Owner: Developer 1
- [ ] `P0-108` Configure structured logging and request IDs. Owner: Developer 1
- [ ] `P0-109` Add shared API error and response formats. Owner: Developer 1
- [ ] `P0-110` Configure SQLAlchemy, Psycopg, and Alembic. Owner: Developer 1
- [ ] `P0-111` Create the initial database migration. Owner: Developer 1

### Flutter Foundation

- [ ] `P0-112` Initialize the Flutter Android and Web targets. Owner: Developer 2
- [ ] `P0-113` Add Riverpod, `go_router`, Dio, Freezed, and serialization packages. Owner: Developer 2
- [ ] `P0-114` Create the theme, router, API client, and environment configuration. Owner: Developer 2
- [ ] `P0-115` Add global loading, empty, offline, and error states. Owner: Developer 2
- [ ] `P0-116` Add English, Hindi, and Marathi localization scaffolding. Owner: Developer 2

### Integration and CI

- [ ] `P0-117` Agree on endpoint paths and request/response models. Owner: Both
- [ ] `P0-118` Connect Flutter to the FastAPI health endpoint. Owner: Both
- [ ] `P1-119` Add GitHub Actions for backend tests and Flutter analysis. Owner: Both

### Phase Exit Criteria

- Flutter Android and Web builds run.
- FastAPI starts and connects to PostgreSQL.
- Flutter displays the backend health result.

---

## Phase 2 - Authentication and Student Profile

Target: Day 1

### Firebase Authentication

- [ ] `P0-201` Add Firebase configuration to Flutter. Owner: Developer 2
- [ ] `P0-202` Build phone-number entry, OTP entry, resend, loading, and error states. Owner: Developer 2
- [ ] `P0-203` Test login with Firebase test phone numbers. Owner: Developer 2
- [ ] `P0-204` Add logout and account-deletion actions. Owner: Developer 2
- [ ] `P0-205` Configure Firebase Admin SDK in FastAPI. Owner: Developer 1
- [ ] `P0-206` Verify bearer tokens and expose the authenticated Firebase UID. Owner: Developer 1
- [ ] `P0-207` Add citizen and administrator authorization dependencies. Owner: Developer 1

### User and Profile Backend

- [ ] `P0-208` Create `users` and `student_profiles` tables. Owner: Developer 1
- [ ] `P0-209` Add user creation on first authenticated request. Owner: Developer 1
- [ ] `P0-210` Add profile read, create, and update endpoints. Owner: Developer 1
- [ ] `P0-211` Derive age from date of birth on the backend. Owner: Developer 1
- [ ] `P0-212` Preserve missing optional values as null. Owner: Developer 1
- [ ] `P0-213` Add account-deletion cleanup for profile data. Owner: Developer 1

### Profile Flutter Flow

- [ ] `P0-214` Build the student profile form. Owner: Developer 2
- [ ] `P0-215` Add controlled selections for state, education level, institution type, and category. Owner: Developer 2
- [ ] `P0-216` Explain optional sensitive fields before collection. Owner: Developer 2
- [ ] `P0-217` Add save, validation, retry, and edit states. Owner: Developer 2
- [ ] `P0-218` Route authenticated users with incomplete profiles to profile creation. Owner: Developer 2

### Phase Exit Criteria

- A test user can complete OTP login.
- FastAPI recognizes the Firebase identity.
- The user can create, retrieve, and edit a student profile.

---

## Phase 3 - Scheme Catalog, Eligibility, and Recommendations

Target: Day 1 afternoon through Day 2 morning

### Scheme Data

- [ ] `P0-301` Create tables for schemes, sources, deadlines, rules, and required documents. Owner: Developer 1
- [ ] `P0-302` Add publication and validation-status fields. Owner: Developer 1
- [ ] `P0-303` Implement a repeatable dataset seed command. Owner: Developer 1
- [ ] `P0-304` Validate seed records before database insertion. Owner: Developer 1
- [ ] `P0-305` Seed the frozen 25-scheme dataset. Owner: Developer 1

### Scheme APIs and Screens

- [ ] `P0-306` Add paginated scheme search and filter endpoints. Owner: Developer 1
- [ ] `P0-307` Add a scheme-detail endpoint with sources and deadlines. Owner: Developer 1
- [ ] `P0-308` Build scheme search, filter, list, and empty states. Owner: Developer 2
- [ ] `P0-309` Build scheme details with benefits, requirements, deadlines, and source links. Owner: Developer 2
- [ ] `P1-310` Visually label search-only and expired records. Owner: Developer 2

### Eligibility Engine

- [ ] `P0-311` Implement typed rule and condition models. Owner: Developer 1
- [ ] `P0-312` Implement `and`, `or`, and nested rule groups. Owner: Developer 1
- [ ] `P0-313` Implement equality, list, range, and numeric operators. Owner: Developer 1
- [ ] `P0-314` Implement missing-value handling as Unresolved. Owner: Developer 1
- [ ] `P0-315` Separate mandatory and advisory outcomes. Owner: Developer 1
- [ ] `P0-316` Produce Potentially Eligible, More Information Needed, and Not Matched statuses. Owner: Developer 1
- [ ] `P0-317` Add unit tests for every operator and status transition. Owner: Developer 1

### Confidence and Ranking

- [ ] `P0-318` Implement configured confidence components and labels. Owner: Developer 1
- [ ] `P0-319` Ensure confidence cannot override a failed mandatory rule. Owner: Developer 1
- [ ] `P0-320` Implement benefit, document, deadline, education, and advisory ranking signals. Owner: Developer 1
- [ ] `P0-321` Exclude Not Matched and search-only records from Top 3. Owner: Developer 1
- [ ] `P0-322` Add the recommendation endpoint. Owner: Developer 1
- [ ] `P0-323` Run benchmark profiles and record Top 3 accuracy. Owner: Both

### Recommendation UI

- [ ] `P0-324` Build the Top 3 recommendation screen. Owner: Developer 2
- [ ] `P0-325` Display status, confidence, satisfied, unresolved, and failed conditions. Owner: Developer 2
- [ ] `P0-326` Keep Not Matched schemes accessible from catalog results. Owner: Developer 2
- [ ] `P0-327` Prompt users to complete fields causing unresolved conditions. Owner: Developer 2

### Phase Exit Criteria

- The frozen dataset is searchable.
- Benchmark profiles produce deterministic results.
- The Android app displays Top 3 recommendations and transparent rule outcomes.

---

## Phase 4 - RAG, AI Explanations, and Assistant

Target: Day 2

### Knowledge Ingestion

- [ ] `P0-401` Create knowledge-document and knowledge-chunk tables. Owner: Developer 1
- [ ] `P0-402` Extract text from normal PDFs with PyMuPDF. Owner: Developer 1
- [ ] `P1-403` Add Tesseract fallback for scanned PDF pages. Owner: Developer 1
- [ ] `P0-404` Split approved text into source-aware chunks. Owner: Developer 1
- [ ] `P0-405` Generate 768-dimensional embeddings. Owner: Developer 1
- [ ] `P0-406` Store source, page, date, status, and scheme metadata with each chunk. Owner: Developer 1

### Retrieval

- [ ] `P0-407` Implement pgvector similarity retrieval. Owner: Developer 1
- [ ] `P0-408` Filter retrieval by scheme and published status. Owner: Developer 1
- [ ] `P0-409` Return source metadata with every retrieved chunk. Owner: Developer 1
- [ ] `P0-410` Add retrieval tests for known scheme questions. Owner: Developer 1

### Gemini and LangGraph

- [ ] `P0-411` Configure the backend-only Gemini client. Owner: Developer 1
- [ ] `P0-412` Define structured schemas for explanations, checklists, and chat answers. Owner: Developer 1
- [ ] `P0-413` Build the fixed LangGraph workflow. Owner: Developer 1
- [ ] `P0-414` Pass deterministic results into the explanation node. Owner: Developer 1
- [ ] `P0-415` Require citations and last-verified dates in generated output. Owner: Developer 1
- [ ] `P0-416` Reject citations not present in retrieved sources. Owner: Developer 1
- [ ] `P0-417` Implement the insufficient-information fallback response. Owner: Developer 1
- [ ] `P0-418` Add Gemini timeout, retry, and unavailable-service handling. Owner: Developer 1

### Flutter AI Experience

- [ ] `P0-419` Add source-backed explanations to recommendation details. Owner: Developer 2
- [ ] `P0-420` Build the scoped AI Assistant interface. Owner: Developer 2
- [ ] `P0-421` Render citations as official-source actions. Owner: Developer 2
- [ ] `P0-422` Add unsupported-question, timeout, and retry states. Owner: Developer 2
- [ ] `P1-423` Pass the selected English, Hindi, or Marathi response language. Owner: Developer 2

### Phase Exit Criteria

- Recommendation explanations cite approved sources.
- The assistant answers supported questions and refuses unsupported ones.
- Gemini does not alter deterministic eligibility outcomes.

---

## Phase 5 - OCR, Document Analysis, and Checklist

Target: Day 2

### Document Capture and OCR

- [ ] `P0-501` Add camera and gallery document selection. Owner: Developer 2
- [ ] `P0-502` Add document-type selection for Aadhaar, PAN, and Income Certificate. Owner: Developer 2
- [ ] `P0-503` Integrate ML Kit Text Recognition. Owner: Developer 2
- [ ] `P0-504` Add blur, empty-text, and rescan handling. Owner: Developer 2
- [ ] `P0-505` Parse required fields from synthetic Aadhaar documents. Owner: Developer 2
- [ ] `P0-506` Parse required fields from synthetic PAN documents. Owner: Developer 2
- [ ] `P0-507` Parse required fields from synthetic Income Certificates. Owner: Developer 2
- [ ] `P0-508` Mask Aadhaar and PAN identifiers before persistence. Owner: Developer 2

### Document Backend

- [ ] `P0-509` Create document metadata and extraction tables. Owner: Developer 1
- [ ] `P0-510` Add a document comparison endpoint. Owner: Developer 1
- [ ] `P0-511` Compare name, date of birth, income, and validity fields. Owner: Developer 1
- [ ] `P0-512` Classify minor differences as warnings. Owner: Developer 1
- [ ] `P0-513` Classify major differences as correction or re-upload requirements. Owner: Developer 1
- [ ] `P0-514` Ensure responses never claim legal authenticity. Owner: Developer 1

### Optional Document Storage

- [ ] `P1-515` Generate a signed Supabase upload URL. Owner: Developer 1
- [ ] `P1-516` Upload only when the user selects saved storage. Owner: Developer 2
- [ ] `P1-517` Add user ownership checks for document metadata. Owner: Developer 1
- [ ] `P1-518` Add user and account-deletion file cleanup. Owner: Developer 1
- [ ] `P1-519` Remove failed and temporary files. Owner: Developer 1

### Checklist

- [ ] `P0-520` Generate checklist items from scheme requirements. Owner: Developer 1
- [ ] `P0-521` Mark available, missing, warning, and correction states. Owner: Developer 1
- [ ] `P0-522` Add application steps to the checklist response. Owner: Developer 1
- [ ] `P0-523` Build the checklist screen and completion controls. Owner: Developer 2
- [ ] `P0-524` Run checklist accuracy tests against benchmark fixtures. Owner: Both

### Phase Exit Criteria

- The app analyzes all three synthetic document types.
- Full identifiers are not persisted or logged.
- A validated scheme produces a personalized document checklist.

---

## Phase 6 - Citizen Completion Features

Target: Day 2 evening through Day 3 morning

### Saved Schemes and Status

- [ ] `P0-601` Create saved-scheme and status records. Owner: Developer 1
- [ ] `P0-602` Add save, unsave, and status-update endpoints. Owner: Developer 1
- [ ] `P0-603` Build saved-scheme and status controls. Owner: Developer 2
- [ ] `P0-604` Support all seven defined manual statuses. Owner: Developer 2

### Reminders

- [ ] `P0-605` Request Android notification permission. Owner: Developer 2
- [ ] `P0-606` Create a reminder from a fixed scheme deadline. Owner: Developer 2
- [ ] `P0-607` Allow a user-defined date when no deadline exists. Owner: Developer 2
- [ ] `P1-608` Add edit and delete reminder actions. Owner: Developer 2

### Official Portal

- [ ] `P0-609` Show a leave-Schemora confirmation dialog. Owner: Developer 2
- [ ] `P0-610` Open the approved application URL in the external browser. Owner: Developer 2
- [ ] `P0-611` Record the Official Portal Opened analytics event. Owner: Developer 1

### Cache, Analytics, and Language

- [ ] `P1-612` Cache previously viewed public scheme details with Drift. Owner: Developer 2
- [ ] `P1-613` Cache the selected language preference. Owner: Developer 2
- [ ] `P1-614` Add the approved privacy-safe analytics events. Owner: Developer 1
- [ ] `P1-615` Translate the critical citizen flow into Hindi and Marathi. Owner: Developer 2
- [ ] `P1-616` Verify AI responses follow the selected language. Owner: Both
- [ ] `P1-617` Add English and Hindi speech-to-text. Owner: Developer 2
- [ ] `P1-618` Add English and Hindi text-to-speech. Owner: Developer 2
- [ ] `P2-619` Add an in-app notice for materially updated saved schemes. Owner: Both

### Phase Exit Criteria

- The citizen can save a scheme, set a status, create a reminder, and open the official portal.
- The primary flow is usable in English, Hindi, and Marathi.

---

## Phase 7 - Admin Dashboard

Target: Day 3

### Administrator Access

- [ ] `P0-701` Add administrator role records and seed one evaluator account. Owner: Developer 1
- [ ] `P0-702` Build the admin email, password, and OTP screen. Owner: Developer 2
- [ ] `P0-703` Add role-gated admin routing. Owner: Developer 2
- [ ] `P0-704` Verify every admin API rejects citizen tokens. Owner: Developer 1

### Scheme Management

- [ ] `P0-705` Add admin scheme list and detail endpoints. Owner: Developer 1
- [ ] `P0-706` Add create, edit, delete, and validation endpoints. Owner: Developer 1
- [ ] `P0-707` Build scheme list, form, validation, and delete-confirmation screens. Owner: Developer 2

### Knowledge Publication

- [ ] `P0-708` Add official PDF upload. Owner: Both
- [ ] `P0-709` Display extracted text for review and editing. Owner: Developer 2
- [ ] `P0-710` Save reviewed text as an approved source draft. Owner: Developer 1
- [ ] `P0-711` Add embedding-generation action and progress state. Owner: Both
- [ ] `P0-712` Add publish and unpublish actions. Owner: Both
- [ ] `P0-713` Confirm unpublished chunks are absent from citizen retrieval. Owner: Both
- [ ] `P1-714` Display basic event counts. Owner: Developer 2

### Phase Exit Criteria

- An administrator can edit a scheme and publish reviewed source content.
- Published content is retrievable; unpublished content is not.
- Citizen users cannot access admin operations.

---

## Phase 8 - Reliability, Security, and Validation

Target: Day 3

### Failure Scenarios

- [ ] `P0-801` Simulate Gemini unavailability and verify retry behavior. Owner: Both
- [ ] `P0-802` Simulate OCR failure and verify rescan behavior. Owner: Developer 2
- [ ] `P0-803` Simulate network loss and verify offline messaging. Owner: Developer 2
- [ ] `P0-804` Verify invalid OTP feedback and resend limits. Owner: Developer 2
- [ ] `P0-805` Simulate backend unavailability and verify retry behavior. Owner: Both

### Security and Privacy

- [ ] `P0-806` Search logs and database fixtures for full Aadhaar and PAN values. Owner: Developer 1
- [ ] `P0-807` Verify users cannot access another user's documents. Owner: Developer 1
- [ ] `P0-808` Verify citizen users cannot call admin APIs. Owner: Developer 1
- [ ] `P0-809` Verify private documents have no permanent public URL. Owner: Developer 1
- [ ] `P0-810` Verify account deletion removes owned profile and files. Owner: Both
- [ ] `P0-811` Confirm no secrets exist in Flutter assets or Git-tracked files. Owner: Both

### Benchmark and Performance

- [ ] `P0-812` Run all benchmark profiles and calculate Top 3 accuracy. Owner: Both
- [ ] `P0-813` Run checklist fixtures and calculate checklist accuracy. Owner: Both
- [ ] `P0-814` Time profile save, recommendation, chat, and OCR operations. Owner: Both
- [ ] `P0-815` Correct failures below the 80% recommendation target. Owner: Developer 1
- [ ] `P0-816` Correct failures below the 90% checklist target. Owner: Both
- [ ] `P1-817` Run Flutter unit and widget tests. Owner: Developer 2
- [ ] `P1-818` Run backend unit and API tests. Owner: Developer 1

### Phase Exit Criteria

- Required failure scenarios are recoverable.
- Privacy and ownership checks pass.
- Recommendation and checklist metrics meet their targets.

---

## Phase 9 - Deployment and Delivery

Target: Day 3 final hours

### Hosted Services

- [ ] `P0-901` Deploy the FastAPI service to Render. Owner: Developer 1
- [ ] `P0-902` Apply production/evaluation database migrations. Owner: Developer 1
- [ ] `P0-903` Seed the validated scheme and benchmark data. Owner: Developer 1
- [ ] `P0-904` Configure Render environment variables. Owner: Developer 1
- [ ] `P0-905` Configure Android Firebase files without committing secrets. Owner: Developer 2
- [ ] `P0-906` Verify Supabase private buckets and pgvector queries. Owner: Developer 1

### Builds

- [ ] `P0-907` Build the release APK. Owner: Developer 2
- [ ] `P0-908` Build and deploy the Flutter Web admin dashboard. Owner: Developer 2
- [ ] `P0-909` Install the APK on the evaluation device. Owner: Developer 2
- [ ] `P0-910` Run a complete smoke test against hosted services. Owner: Both

### Demonstration Package

- [ ] `P0-911` Prepare citizen and administrator test credentials. Owner: Both
- [ ] `P0-912` Prepare one primary benchmark profile for the live demonstration. Owner: Both
- [ ] `P0-913` Prepare one document from each supported synthetic type. Owner: Developer 2
- [ ] `P0-914` Write a reset procedure for repeat demonstrations. Owner: Developer 1
- [ ] `P0-915` Write the exact citizen and admin demonstration sequence. Owner: Both
- [ ] `P0-916` Warm the Render service before evaluation. Owner: Developer 1
- [ ] `P0-917` Tag the evaluated source revision. Owner: Both

### Final Exit Criteria

- The APK is installable and connected to the hosted API.
- The administrator dashboard is accessible.
- Both required workflows complete using synthetic data.
- All five required failure scenarios can be demonstrated.
- The evaluated revision and dataset are frozen.

---

## Three-Day Parallel Schedule

### Day 1

Developer 1:

- Backend foundation
- Database migrations
- Firebase token verification
- Profile APIs
- Scheme seed importer
- Eligibility engine

Developer 2:

- Flutter foundation
- OTP login
- Profile form
- Scheme catalog screens
- Recommendation result states

Shared checkpoint:

- Login, create profile, and display deterministic recommendations from seeded data.

### Day 2

Developer 1:

- pgvector ingestion and retrieval
- Gemini and LangGraph workflow
- Document comparison
- Checklist generation

Developer 2:

- AI explanation and assistant UI
- OCR and field extraction
- Document result UI
- Checklist UI
- Reminders and statuses

Shared checkpoint:

- Complete the citizen workflow through checklist and official portal redirect.

### Day 3

Developer 1:

- Admin APIs
- Publication workflow
- Security tests
- Render and Supabase deployment
- Benchmark validation

Developer 2:

- Flutter Web admin
- Localization and voice
- Failure states
- APK and web builds
- Demonstration setup

Shared checkpoint:

- Run the full citizen workflow, admin workflow, and required failure scenarios.

---

## Evaluation Traceability

| Required Demonstration                  | Implemented In |
| --------------------------------------- | -------------- |
| Mobile OTP Login                        | Phase 2        |
| Student Profile Creation                | Phase 2        |
| Top 3 Recommendations                   | Phase 3        |
| Eligibility Explanation and Citations   | Phase 4        |
| OCR Document Scan                       | Phase 5        |
| Document Consistency Analysis           | Phase 5        |
| Personalized Checklist                  | Phase 5        |
| Reminder Creation                       | Phase 6        |
| Manual Status Update                    | Phase 6        |
| Official Portal Redirect                | Phase 6        |
| Admin Login and Scheme CRUD             | Phase 7        |
| PDF Review, Embeddings, and Publication | Phase 7        |
| Failure Scenarios                       | Phase 8        |
| Hosted APK and Admin Dashboard          | Phase 9        |

## Scope Reduction Order

If the schedule slips, reduce work in this order without breaking the core evaluation:

1. Remove additional search-only schemes.
2. Reduce analytics to stored event counts without charts.
3. Limit offline caching to the last viewed scheme.
4. Defer the saved-scheme update notice.
5. Limit Tesseract fallback to one prepared scanned PDF.
6. Demonstrate voice on one English and one Hindi path only.
7. Reduce visual polish while preserving loading, error, and confirmation states.

Do not cut:

- Deterministic eligibility
- Official citations
- Synthetic document privacy protections
- Citizen and admin authorization
- Top 3 benchmark validation
- Checklist validation
- Required failure handling
- Official portal confirmation

## Definition of Done

The MVP is complete when:

- Every `P0` task is complete.
- The frozen scheme and benchmark datasets are versioned.
- Recommendation and checklist quality targets pass.
- The Android APK and admin dashboard use the hosted FastAPI service.
- The citizen, administrator, and failure demonstration flows pass from a clean reset.
- No real identity documents or production citizen data are present.

