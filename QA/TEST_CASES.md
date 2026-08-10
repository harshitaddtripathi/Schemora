# Schemora - QA Test Cases Specification (Phases 0, 1, 2, 3 & 4)

**Version**: 1.3.0  
**Status**: Approved & Executed  
**Author**: Schemora Automated QA Testing Agent  

---

## 1. Phase 0 - Data Architecture & Eligibility Engine

### 1.1 JSON Schema Validation (`TC-P0-SCH`)
| Test ID | Summary | Target Artifacts | Expected Result | Status |
| --- | --- | --- | --- | --- |
| `TC-P0-SCH-001` | Scheme JSON Schema Compliance | `data/schemes/schemes.v1.json` | Validates against `scheme.schema.json` (Draft 2020-12) with zero errors. | **PASS** |
| `TC-P0-SCH-002` | Benchmark Profile Schema Compliance | `data/benchmark_profiles/profiles.v1.json` | Validates against `benchmark-profile.schema.json`. | **PASS** |
| `TC-P0-SCH-003` | Expected Results Schema Compliance | `data/benchmark_profiles/expected-results.v1.json` | Validates against `expected-result.schema.json`. | **PASS** |
| `TC-P0-SCH-004` | Confidence & Ranking Weight Schema | `data/config/*.json` | Validates against `confidence-weights` and `ranking-weights` schemas. | **PASS** |
| `TC-P0-SCH-005` | Dataset Manifest Schema | `data/dataset-manifest.v1.json` | Validates against `dataset-manifest.schema.json`. | **PASS** |
| `TC-P0-SCH-006` | Synthetic Sidecar JSON Schema | `data/synthetic_documents/*/*.json` | Validates against `synthetic-document.schema.json`. | **PASS** |

### 1.2 Data Integrity & Cross-References (`TC-P0-INT`)
| Test ID | Summary | Target Artifacts | Expected Result | Status |
| --- | --- | --- | --- | --- |
| `TC-P0-INT-001` | Identifier Uniqueness | `schemes`, `profiles`, `sources`, `inventory` | `scheme_id`, `profile_id`, `source_id` are unique without duplicates. | **PASS** |
| `TC-P0-INT-002` | Inventory Slot Capacity | `scheme-inventory.v1.csv` | Exactly 25 rows (3 Implemented, 22 PlannedResearch). | **PASS** |
| `TC-P0-INT-003` | Jurisdiction & State Nullability | Schemes & Inventory records | Central schemes have `state=null`; State schemes specify valid state. | **PASS** |
| `TC-P0-INT-004` | Student Profile Age Integrity | `profiles.v1.json` | `age` matches exact calculation from `date_of_birth` and `age_as_of`. | **PASS** |
| `TC-P0-INT-005` | Source Register Foreign Keys | `sources/source-register.csv` | All sources map to valid implemented `scheme_id`s. | **PASS** |

---

## 2. Phase 4 - RAG, AI Explanations & Scoped AI Assistant

### 2.1 RAG Vector Search & Chunking (`TC-P4-RAG`)
| Test ID | Summary | Target Component | Expected Result | Status |
| --- | --- | --- | --- | --- |
| `TC-P4-RAG-001` | Text Chunking Algorithm | `app.services.rag_service` | Splits text into 500-char chunks with 50-char overlap cleanly. | **PASS** |
| `TC-P4-RAG-002` | TF-IDF Cosine Similarity Search | `app.services.rag_service` | Calculates term frequency and cosine similarity scores accurately. | **PASS** |

### 2.2 Grounded Gemini AI Engine & Chat (`TC-P4-AI`)
| Test ID | Summary | Target Component | Expected Result | Status |
| --- | --- | --- | --- | --- |
| `TC-P4-AI-001` | Out-Of-Scope Question Detection | `app.services.gemini_service` | Detects non-scheme questions and returns polite redirection fallback. | **PASS** |
| `TC-P4-AI-002` | Recommendation Explanation Endpoint | `POST /api/v1/ai/explain-recommendation` | Returns grounded explanation with official source citations. | **PASS** |
| `TC-P4-AI-003` | Scoped Q&A Chat Endpoint | `POST /api/v1/ai/chat` | Answers scheme questions and validates citations against retrieved context. | **PASS** |
| `TC-P4-AI-004` | Flutter AI Chat UI Model | `frontend/lib/features/ai_assistant/` | Deserializes `SourceCitationModel` and `ChatMessageModel` cleanly. | **PASS** |
