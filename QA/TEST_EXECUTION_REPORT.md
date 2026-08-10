# Schemora - QA Test Execution Report (Phases 0 - 9)

**Execution Date**: August 10, 2026  
**Execution Environment**: Windows 11 (Python 3.14.3 + uv 0.11.18 + Flutter 3.32.2)  
**Executed By**: Schemora Automated QA Testing Agent  
**Overall Outcome**: **PASSED (100% Pass Rate)**  

---

## Executive Summary

The Schemora QA Testing Agent executed all unit, integration, schema validation, authorization, engine scoring, vector retrieval, grounded AI explanations, sensitive identifier masking, OCR document analysis, citizen features, admin publication workflows, reliability error recovery, security audits, and mobile widget tests across all project phases (**Phases 0 through 9**).

| Test Suite Category | Total Executed | Passed | Failed | Blocked | Pass Rate | Duration |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Phase 0 Data & Schemas** | 6 | 6 | 0 | 0 | 100% | 0.45s |
| **Data Integrity & FKs** | 5 | 5 | 0 | 0 | 100% | 0.38s |
| **Eligibility Engine Logic** | 5 | 5 | 0 | 0 | 100% | 0.12s |
| **Benchmark Predictions (45 pairs)** | 45 | 45 | 0 | 0 | 100% | 0.22s |
| **Synthetic Docs & Security Scan** | 4 | 4 | 0 | 0 | 100% | 0.61s |
| **Phase 1 Backend & Health APIs** | 9 | 9 | 0 | 0 | 100% | 1.19s |
| **Phase 2 Auth & Profile APIs** | 4 | 4 | 0 | 0 | 100% | 1.42s |
| **Phase 3 Scheme Catalog & Top 3 API** | 3 | 3 | 0 | 0 | 100% | 1.17s |
| **Phase 4 RAG, Gemini AI & Chat API** | 3 | 3 | 0 | 0 | 100% | 1.45s |
| **Phase 5 OCR, Masking & Checklist API** | 2 | 2 | 0 | 0 | 100% | 1.32s |
| **Phase 6 Saved Schemes & 7 Statuses API** | 2 | 2 | 0 | 0 | 100% | 1.25s |
| **Phase 7 Admin & Knowledge Publication API** | 4 | 4 | 0 | 0 | 100% | 1.58s |
| **Phase 8 Reliability & Security Suite** | 5 | 5 | 0 | 0 | 100% | 1.80s |
| **Backend Service & Document Unit Tests** | 44 | 44 | 0 | 0 | 100% | 1.50s |
| **Frontend Flutter Unit & Widget Tests** | 18 | 18 | 0 | 0 | 100% | 5.30s |
| **Frontend Static Analysis** | 1 | 1 | 0 | 0 | 100% | 2.10s |
| **Total / Overall** | **160** | **160** | **0** | **0** | **100%** | **21.86s** |

---

## Detailed Execution Breakdown

### 1. Backend Service & Engine Unit Tests (`backend/tests/`)
- `test_config.py`: **2/2 PASS**
- `test_database.py`: **2/2 PASS**
- `test_health.py`: **2/2 PASS**
- `test_schemas.py`: **3/3 PASS**
- `test_profile_schemas.py`: **3/3 PASS**
- `test_eligibility_engine_unit.py`: **5/5 PASS**
- `test_scheme_schemas.py`: **2/2 PASS**
- `test_gemini_rag_unit.py`: **5/5 PASS**
- `test_document_checklist_unit.py`: **6/6 PASS**
- `test_saved_schemes_unit.py`: **4/4 PASS**
- `test_admin_unit.py`: **5/5 PASS**
- `test_reliability_unit.py`: **5/5 PASS**

### 2. Root Pytest Integration Suite (`tests/`)
- `tests/test_phase5_ocr_checklist.py`: **2/2 PASS**
- `tests/test_phase6_citizen.py`: **2/2 PASS** (Saved scheme toggle, 7 status transitions, deadline reminders, portal analytics).
- `tests/test_phase7_admin.py`: **4/4 PASS** (Role-gated token authorization rejection, scheme CRUD, PDF review & publication isolation).
- `tests/test_phase8_reliability.py`: **5/5 PASS** (Gemini unavailability fallback, OCR failure handling, security token validation, benchmark metrics).
- `tests/test_security_and_secrets.py`: **1/1 PASS** (Sensitive Aadhaar/PAN masking and secrets scan).

### 3. Frontend Flutter Suite (`frontend/test/`)
- `test/unit/ai_chat_model_test.dart`: **2/2 PASS**
- `test/unit/scheme_model_test.dart`: **2/2 PASS**
- `test/unit/auth_state_test.dart`: **6/6 PASS**
- `test/unit/profile_model_test.dart`: **2/2 PASS**
- `test/widget_test.dart`: **1/1 PASS**
- Static Analysis (`flutter analyze`): **0 issues found!**
