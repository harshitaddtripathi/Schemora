# Schemora - MVP Project Scope

## 1. Document Purpose

This document defines the functional scope, constraints, data boundaries, architecture, and acceptance criteria for the Schemora MVP prototype.

The MVP is intended for academic evaluation and proof of concept. It is not a public production release and does not claim production-grade compliance, availability, security certification, or complete coverage of every government scheme.

---

## 2. Product Overview

Schemora is an AI-assisted Flutter mobile application that helps Indian citizens discover, understand, and prepare to apply for government welfare schemes.

The MVP focuses on students seeking scholarships, education assistance, skill-development programs, employment support, entrepreneurship support, financial assistance, and related social-welfare benefits.

Schemora combines:

- Deterministic eligibility evaluation
- Retrieval-Augmented Generation (RAG) over verified official sources
- AI-generated explanations and application guidance
- OCR-based document analysis
- Personalized document checklists
- Multilingual text and limited voice support
- Local reminders and manual application-status tracking

Schemora does not submit applications to government systems. It prepares the user and redirects them to the official government application portal.

---

## 3. Problem Statement

Citizens often struggle to:

- Discover schemes relevant to their circumstances
- Understand complex or fragmented eligibility requirements
- Identify missing profile information and supporting documents
- Interpret official notifications and application instructions
- Track deadlines and their own application progress
- Navigate multiple government websites

Existing platforms frequently require users to search and compare schemes manually. Schemora reduces this effort through structured eligibility rules, verified source retrieval, and guided application preparation.

---

## 4. MVP Goal

The goal is to demonstrate a complete AI-assisted citizen journey:

1. Authenticate with a mobile number.
2. Create a student profile.
3. Receive personalized scheme recommendations.
4. Understand matched, unresolved, and failed eligibility conditions.
5. Analyze supported documents with OCR.
6. Generate a personalized application checklist.
7. Create a deadline reminder and track application status.
8. Continue to the official government application portal.

The architecture should permit future expansion, but production hardening and nationwide scheme completeness are outside the three-day prototype.

---

## 5. Release Profile

| Item | MVP Decision |
| --- | --- |
| Deliverable | Functional academic MVP prototype |
| Development period | 3 development days |
| Team size | 2 developers |
| Primary platform | Android |
| Client | Installable Flutter APK |
| Primary persona | Students |
| Country | India |
| Authentication | Mobile number with Firebase Phone OTP |
| Backend | Hosted Python FastAPI service on Render |
| Database | Supabase PostgreSQL |
| Vector storage | PostgreSQL with pgvector |
| Document storage | Private Supabase Storage |
| AI | Gemini API with LangChain and LangGraph |
| Release audience | Academic evaluators and controlled test users |

---

## 6. Geographic and Scheme Coverage

The application accepts profiles from every Indian State and Union Territory and is designed for future nationwide expansion.

The curated MVP dataset does not claim complete State Government scheme coverage across India. It contains 25 fully validated schemes consisting of Central Government schemes and representative State Government schemes from:

- Maharashtra
- Gujarat
- Karnataka
- Tamil Nadu
- Uttar Pradesh
- Rajasthan
- Madhya Pradesh
- Delhi (NCT)

Users from other States and Union Territories can still be matched with applicable Central Government schemes. State-specific recommendations are limited to the jurisdictions represented in the curated dataset.

The 25 validated schemes support the complete workflow:

- Deterministic eligibility assessment
- Source-backed AI explanation
- Required-document mapping
- Personalized checklist generation
- Application guidance
- Official portal redirection

Additional schemes may be included as search-only records. Search-only schemes must be clearly identified and must not appear in personalized Top 3 recommendations until their rules, sources, documents, and application guidance have been validated.

### Dataset Freeze Requirement

The exact list of 25 schemes, official URLs, source documents, normalized rules, and expected test results must be frozen before feature implementation and stored as a separate version-controlled dataset artifact.

---

## 7. Users and Roles

### 7.1 Citizen User

The primary user is a student seeking government benefits. Each MVP account manages only the authenticated user's profile.

Family-member profiles and household account management are outside the MVP.

### 7.2 Administrator

Administrators maintain scheme records and the RAG knowledge base.

Administrator roles:

- Are manually assigned in the database
- Cannot be self-created
- Cannot be granted or modified by normal users

Administrators authenticate with:

- Admin email
- Strong password
- Second-factor OTP verification

---

## 8. Citizen Functional Scope

### 8.1 Authentication and Account Management

The citizen application supports:

- Mobile-number sign-in using Firebase Phone OTP
- OTP validity target of 5 minutes
- Maximum of 3 resend attempts per verification session
- Firebase test phone numbers for evaluation
- Verified phone-number updates
- Logout
- Account deletion from profile settings

Deleting an account must trigger deletion of the associated profile, saved document metadata, and stored document files.

### 8.2 Student Profile

The student profile contains:

- Full name
- Date of birth
- Age, derived from date of birth
- Gender
- State
- District
- Education level
- Institution type
- Course
- Academic percentage or CGPA
- Annual family income
- Category: General, OBC, SC, ST, or EWS
- Disability status
- Minority status
- Mobile number
- Email address

The mobile number is obtained from authentication. Optional profile fields may be skipped and completed later.

Category, disability status, and minority status are explicitly optional. When the application requests sensitive information, it must explain why the information is relevant to recommendations.

Missing values must not be interpreted as failed eligibility conditions.

### 8.3 Scheme Discovery

Users can:

- Search supported schemes
- Filter schemes by category, jurisdiction, state, and status
- View Central and applicable State Government schemes
- View active, upcoming, expired, recurring, and continuously open schemes
- View matched and not-matched schemes
- Open scheme details, benefits, requirements, deadlines, sources, and application instructions

### 8.4 Personalized Recommendations

The system generates Top 3 personalized recommendations using deterministic eligibility results and a deterministic ranking process.

Each recommendation must show:

- Recommendation status
- Confidence percentage and label
- Satisfied mandatory conditions
- Unresolved conditions
- Relevant advisory conditions
- Explanation of why the scheme was recommended
- Required documents
- Application deadline or deadline status
- Official source citations
- Last verified date
- Official application link

Not-matched schemes remain searchable and visible. They must explain which mandatory conditions were not satisfied, but they are excluded from the Top 3 recommendations.

### 8.5 AI Assistant

The in-app AI Assistant can answer questions about:

- Supported schemes
- Eligibility requirements
- Required documents
- Scheme benefits
- Application procedures
- Recommendation explanations

The AI Assistant is restricted to the curated knowledge base. It must not provide unrelated general government, legal, or financial advice.

Every source-dependent answer must include official source citations and a last-verified date.

When the knowledge base lacks sufficient verified information, the assistant must respond:

> Sorry, sufficient verified information is not available in the current knowledge base. Please refer to the official government website for the latest details.

### 8.6 Document Analysis

The MVP supports OCR-based analysis for:

- Aadhaar Card
- PAN Card
- Income Certificate

Document analysis checks:

- Readability
- Expected field presence
- Document completeness
- Consistency with the user's profile
- Expiry or validity date when the document provides one

Document analysis does not prove legal authenticity and must not be described as official verification.

### 8.7 Personalized Application Checklist

For a validated scheme, the system generates a checklist from:

- The scheme's required-document records
- The user's profile
- Available analyzed documents
- Missing or inconsistent documents
- Scheme-specific application steps

Checklist items can be marked complete by the user. The checklist must distinguish:

- Available documents
- Missing documents
- Documents with warnings
- Documents requiring correction or re-upload

### 8.8 Application Guidance and Redirection

Schemora provides:

- Eligibility explanations
- Required-document guidance
- Personalized checklist generation
- Step-by-step application instructions
- A link to the official government application portal

Direct application submission is outside the MVP.

Official portals open in the device's external browser. Before redirection, the application displays a confirmation that the user is leaving Schemora and opening an official government website.

### 8.9 Reminders

The MVP uses local Android notifications only.

Users can:

- Create reminders from known scheme deadlines
- Set a manual reminder when no official deadline is available
- Edit or delete reminders

Push notifications, SMS reminders, and email reminders are outside the MVP.

### 8.10 Manual Application Status

Users can assign one of these statuses to a saved scheme:

- Interested
- Preparing Documents
- Ready to Apply
- Applied Externally
- Under Review
- Approved
- Rejected

Schemora does not obtain status information from government systems.

### 8.11 Offline Behavior

The application requires an active internet connection for authentication, recommendation generation, AI responses, OCR processing, and knowledge retrieval.

The offline content cache is limited to:

- Public scheme information
- Previously viewed scheme details
- User language preference

Sensitive profile data, uploaded documents, OCR results, and authentication tokens are not included in the offline content cache.

---

## 9. Administrator Functional Scope

The basic graphical admin dashboard supports:

- Administrator login
- Add, view, edit, and delete scheme records
- Upload official government PDFs and scheme documents
- Review extracted text
- Approve or reject extracted information
- Generate embeddings
- Publish or unpublish knowledge
- Remove outdated information
- View basic event counts

Publishing requires explicit administrator approval. Uploaded or extracted content must not become available to citizen users before approval.

The minimum knowledge-base workflow is:

1. Upload an official document.
2. Extract text.
3. Review and correct extracted content.
4. Associate the content with a scheme and source record.
5. Generate embeddings.
6. Publish the approved version.

Advanced automated ingestion, scheduled crawling, source-change detection, and government API synchronization are outside the MVP.

---

## 10. Scheme Data Model

Each fully validated scheme record contains:

- Scheme ID
- Scheme name
- Short description
- Detailed description
- Benefits
- Jurisdiction: Central or State
- Applicable state, when relevant
- Department
- Beneficiary categories
- Structured eligibility rules
- Required documents
- Application process
- Deadline type
- One or more application windows, when applicable
- Scheme status: Active, Expired, or Upcoming
- One or more source records
- Last verified date
- Publication status

### 10.1 Source Record

Each source record contains:

- Source title
- Source type
- Official information URL
- Official application URL, when available
- Publication date
- Retrieval date
- Last verified date
- Authority priority

URLs used for citizen redirection must come from approved source records.

### 10.2 Source-of-Truth Priority

When official sources conflict, the priority order is:

1. Latest Government Notification
2. Official Scheme Portal
3. Department Website
4. Official PDF Guidelines
5. Official FAQ

The newest applicable official notification is authoritative. Administrators must review conflicts before publishing an updated scheme version.

### 10.3 Deadline Model

A scheme can have one of these deadline types:

- Fixed Date
- Recurring
- Continuous/Open
- Upcoming
- Not Announced
- Expired

The data model supports multiple application windows when required.

### 10.4 Scheme Updates

Saved recommendations display the latest published scheme information.

When a published change materially affects eligibility, benefits, required documents, deadlines, or application instructions, the user receives an in-app notice the next time the application synchronizes. This is an in-app update notice, not a remote push notification.

---

## 11. Eligibility Rules and Recommendation Logic

### 11.1 Rule Representation

Eligibility rules are stored as structured JSON and evaluated by application code rather than by the LLM.

The rule format supports:

- Mandatory and advisory conditions
- AND conditions
- OR conditions
- Nested conditions
- Numeric comparisons
- Age ranges
- Income thresholds
- State and jurisdiction filtering
- Category lists
- Missing values

Typical mandatory conditions include:

- Age
- Income limit
- State or jurisdiction
- Education level
- Category, when required

Typical advisory conditions include:

- Preferred academic score
- Preferred institution type
- Additional recommendation preferences

Advisory conditions can influence ranking but must never disqualify a user.

### 11.2 Eligibility Status

Schemora never makes an official eligibility determination.

The application uses these recommendation statuses:

- Potentially Eligible: all known mandatory conditions are satisfied
- More Information Needed: no mandatory condition failed, but one or more are unresolved
- Not Matched: at least one mandatory condition is not satisfied

When profile information is missing, the condition is marked Unresolved and the user is prompted to provide the relevant information.

### 11.3 Confidence Score

The confidence score represents recommendation confidence, not the probability of government approval.

It is displayed as:

- High: 80-100%
- Medium: 50-79%
- Low: below 50%

The deterministic confidence calculation considers:

- Profile completeness
- Supporting-document availability
- Resolved versus unresolved conditions
- Retrieved source completeness
- Source freshness
- Consistency of the deterministic rule evaluation

A failed mandatory condition cannot be offset by a high confidence score. Eligibility status and confidence are separate values.

Final component weights must be stored as configuration and validated against the benchmark test profiles.

### 11.4 Recommendation Ranking

Schemes without failed mandatory conditions are ranked using:

- Eligibility status
- Confidence score
- Benefit relevance
- Document readiness
- Deadline priority
- Relevance to the user's education profile
- Advisory-condition matches

The highest-ranked three schemes are presented as the Top 3 recommendations.

---

## 12. OCR and Document Data

### 12.1 Extracted Fields

#### Aadhaar Card

- Name
- Year or date of birth
- Gender
- Address
- Masked Aadhaar number or final four characters

#### PAN Card

- Name
- Date of birth
- Masked PAN number or final four characters

#### Income Certificate

- Applicant name
- Annual income
- Issuing authority
- Issue date
- Validity date, when available

### 12.2 Mismatch Handling

Examples of mismatches include:

- Name differences
- Date-of-birth differences
- Income inconsistencies
- Invalid or expired documents
- Missing expected fields

Minor variations, such as likely spelling differences, generate a warning and request user confirmation.

Major inconsistencies require document re-upload or profile correction. The application must explain the mismatch without claiming fraud or inauthenticity.

### 12.3 Identifier Handling

Complete Aadhaar and PAN numbers may exist only transiently during OCR processing.

After extraction:

- Only masked values or final four characters are retained
- Complete identifiers are not stored in PostgreSQL
- Complete identifiers are not written to application logs
- Temporary OCR artifacts containing complete identifiers are deleted after processing

### 12.4 Demonstration Documents

Academic evaluation uses only synthetic, sample, or redacted identity documents. Real identity documents are not required for the MVP demonstration.

---

## 13. Document Storage and Retention

Document metadata is stored in Supabase PostgreSQL.

Document files are stored in a private Supabase Storage bucket with authenticated, user-scoped access controls.

Users choose between:

- Temporary processing only
- Saving the analyzed document for future checklists

Retention behavior:

- Saved documents remain until the user deletes them or deletes the account
- Account deletion removes associated stored files and metadata
- Temporary OCR files are deleted immediately after processing
- Failed uploads are removed automatically
- Document content and complete identifiers are excluded from application logs

---

## 14. AI and RAG Boundaries

### 14.1 Deterministic and AI Responsibilities

Deterministic application code is responsible for:

- Evaluating eligibility rules
- Assigning recommendation status
- Calculating the configured confidence score
- Ranking candidate schemes

RAG and Gemini are responsible for:

- Retrieving approved official information
- Explaining deterministic results
- Answering supported scheme questions
- Summarizing benefits and application procedures
- Generating user-facing guidance from approved scheme data

Gemini must not independently decide whether a user is eligible.

### 14.2 Multi-Agent Workflow

LangGraph coordinates specialized AI responsibilities such as:

- Source retrieval
- Recommendation explanation
- Document-analysis explanation
- Checklist and application guidance
- Scheme question answering

All agents operate within the curated and published knowledge base. Retrieved documents are treated as source data, not executable instructions.

### 14.3 Citation Requirement

AI-generated recommendations and source-dependent answers include:

- Source title
- Official source citation
- Last verified date
- Confidence label, when the response concerns a recommendation

Unsupported claims must not be generated.

---

## 15. Language and Voice Scope

| Capability | MVP Languages |
| --- | --- |
| Static Flutter interface | English, Hindi, Marathi |
| AI responses | English, Hindi, Marathi |
| Scheme translation | AI translation into the selected MVP language |
| OCR | English |
| Speech-to-Text | English, Hindi |
| Text-to-Speech | English, Hindi |

Additional Indian languages and full conversational voice interaction are outside the MVP.

The original official source remains accessible even when AI-generated translation is displayed.

---

## 16. Analytics

The MVP records basic event counts for:

- User Login
- Profile Completion
- Scheme Search
- Scheme Viewed
- Recommendation Generated
- OCR Completed
- Official Portal Opened

Analytics must not contain:

- Sensitive profile values
- Document contents
- Complete or masked identity numbers
- Direct personal identifiers

Advanced analytics, behavioral profiling, and marketing tracking are outside the MVP.

---

## 17. Technical Architecture

### 17.1 Frontend

- Flutter and Dart
- Android APK
- Local Android notifications
- Local cache limited to approved public content and language preference

### 17.2 Backend

- Python FastAPI
- Hosted on Render
- REST APIs for profiles, schemes, recommendations, documents, reminders, statuses, chat, and administration
- Firebase ID-token verification for citizen API access
- Role-based authorization for administrator APIs

### 17.3 Data and Storage

- Supabase PostgreSQL for structured application data
- pgvector for embeddings
- Private Supabase Storage for document files

### 17.4 AI

- Gemini API
- LangChain
- LangGraph
- RAG over administrator-approved source content

### 17.5 OCR

- Google ML Kit or Tesseract OCR
- English-language extraction for the MVP

One OCR implementation must be selected before development begins so that behavior and performance can be tested consistently.

### 17.6 Authentication

- Firebase Authentication for citizen Phone OTP
- Separate administrator email, password, and OTP flow

### 17.7 Development

- Android Studio
- Antigravity/Codex
- Git and GitHub

---

## 18. Security and Privacy Requirements

The prototype must:

- Use authenticated access for citizen and administrator APIs
- Enforce user ownership checks for profiles and documents
- Keep Supabase Storage objects private
- Exclude secrets from source control
- Store service credentials in deployment environment variables
- Mask identity-document numbers in the UI
- Avoid logging document content and sensitive profile values
- Delete temporary OCR artifacts after processing
- Delete user-owned document files and metadata during account deletion
- Restrict publication of knowledge-base content to administrators

These controls reduce prototype risk but do not constitute production compliance certification.

---

## 19. Performance Targets

Under stable evaluation-network conditions and with hosted services already running, the MVP targets:

| Operation | Target |
| --- | --- |
| Scheme recommendations | 3 seconds or less |
| AI chat response | 5 seconds or less |
| OCR processing | 8 seconds or less |
| Profile save | 2 seconds or less |
| OTP verification handling | 5 seconds or less after receipt |

External SMS delivery time, cloud-provider outages, and cold-start delays are measured separately because they are not fully controlled by Schemora.

---

## 20. Failure Handling

The application must leave the user in a recoverable state for these evaluated failures:

- Gemini unavailable: show a temporary-unavailability message and retry action
- OCR extraction failure: request a clearer rescan or re-upload
- Network loss: show an offline notice and retry action
- Invalid OTP: show validation feedback and permit retry within limits
- Backend unavailable: show a service-unavailable message and retry action
- Unsupported AI question: show the verified-information fallback response

The prototype does not guarantee that failures can never occur. Acceptance requires that the listed external-service failures are handled without terminating the active user flow unexpectedly.

---

## 21. Measurable Outcomes

The MVP is evaluated against:

1. At least 80% of predefined test profiles receive the manually approved expected scheme within their Top 3 recommendations.
2. Test users identify a relevant scheme within 3 minutes on average.
3. At least 90% of generated checklists correctly identify required documents for the validated schemes.

The development team creates:

- A fixed set of synthetic student profiles
- Manually verified expected recommendations
- Expected eligibility-condition outcomes
- Expected document checklists
- Official sources supporting each expected result

This benchmark dataset must be frozen with the 25-scheme dataset.

---

## 22. Evaluation and Acceptance Criteria

### 22.1 Citizen Workflow

The evaluation must demonstrate:

1. Mobile OTP login
2. Student profile creation
3. AI-assisted scheme recommendation
4. Top 3 personalized results
5. Eligibility explanation with official source citations
6. OCR-based document scan
7. Document readability, completeness, and consistency analysis
8. Personalized application checklist
9. Local reminder creation
10. Manual application-status update
11. Confirmation and redirect to an official government portal

### 22.2 Administrator Workflow

The evaluation must demonstrate:

1. Administrator login
2. Scheme creation or editing
3. Official PDF upload
4. Extracted-text review
5. Embedding generation
6. Publish and unpublish actions
7. Visibility of published knowledge to the citizen application
8. Basic event counts

### 22.3 Failure Scenarios

The evaluation must demonstrate recoverable handling of:

- Gemini API unavailability
- OCR extraction failure
- Network connectivity loss
- Invalid OTP
- Backend service unavailability

### 22.4 Data Acceptance

Before evaluation:

- The exact 25-scheme inventory is frozen
- Every validated scheme has approved source records
- Every validated scheme has deterministic eligibility rules
- Every validated scheme has a required-document checklist
- Every application URL points to an approved official source
- Benchmark profiles and expected results are frozen
- Search-only schemes are visibly distinguished from validated schemes

---

## 23. Explicit Non-Goals

The MVP does not include:

- Direct government application submission
- Official document-authenticity verification
- Automatic government application-status tracking
- Family-profile management
- Complete State-scheme coverage for every jurisdiction
- Production-grade compliance certification
- Legal or financial advice beyond curated scheme information
- Real-time synchronization with government databases
- Automated crawling or source-change detection
- Government API integrations
- Push, SMS, or email reminders
- iOS release
- Full conversational voice interaction
- General-purpose AI questions outside the curated knowledge base

---

## 24. Delivery Constraints and Risks

The three-day schedule is a rapid prototype constraint. The highest delivery risks are:

- Manually sourcing and validating 25 schemes
- Normalizing heterogeneous eligibility rules
- Preparing benchmark profiles and expected outcomes
- Building both citizen and administrator workflows
- Integrating multiple hosted services
- Meeting response-time targets when free hosting tiers cold-start
- Reliably extracting fields from varied Income Certificate formats

To remain feasible:

- The scheme dataset must be frozen before feature implementation
- Evaluation uses synthetic and predefined data
- The primary happy path takes priority over visual polish
- Search-only schemes are optional
- Advanced analytics and ingestion automation remain excluded
- Production hardening is deferred

---

## 25. Implementation Prerequisites

The following artifacts or decisions remain required before development begins:

1. Name and document the exact 25-scheme inventory.
2. Provide approved source URLs and source files for every scheme.
3. Define and validate the JSON eligibility-rule schema.
4. Freeze the benchmark student profiles and expected Top 3 results.
5. Configure the final confidence-score weights.
6. Select Google ML Kit or Tesseract as the MVP OCR engine.
7. Select the implementation technology for the graphical admin client.
8. Provision Firebase, Gemini, Render, and Supabase development resources.
9. Define environment variables and secret ownership.
10. Prepare synthetic Aadhaar, PAN, and Income Certificate test files.

The MVP scope is considered implementation-ready only after these prerequisites are resolved.

---

## 26. Future Expansion

Potential future releases may add:

- More Central and State Government schemes
- Complete nationwide State-scheme coverage
- Additional Indian interface, AI, OCR, STT, and TTS languages
- Family-member profiles
- iOS support
- Government API integrations
- Automatic application-status tracking
- Automated scheme ingestion and source monitoring
- Push, SMS, and email notifications
- Stronger production security and compliance controls
- Full conversational voice assistance
