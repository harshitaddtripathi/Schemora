# Schemora - QA Test Execution Report (Phases 0, 1, 2, 3, 4 & 5)

**Execution Date**: August 10, 2026  
**Execution Environment**: Windows 11 (Python 3.14.3 + uv 0.11.18 + Flutter 3.32.2)  
**Executed By**: Schemora Automated QA Testing Agent  
**Overall Outcome**: **PASSED (100% Pass Rate)**  

---

## Executive Summary

The Schemora QA Testing Agent executed all unit, integration, schema validation, authorization, engine scoring, vector retrieval, grounded AI explanations, sensitive identifier masking, OCR document analysis, and mobile widget tests across Phases 0, 1, 2, 3, 4, and 5.

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
| **Backend Service & Document Unit Tests** | 30 | 30 | 0 | 0 | 100% | 1.06s |
| **Frontend Flutter Unit & Widget Tests** | 18 | 18 | 0 | 0 | 100% | 5.30s |
| **Frontend Static Analysis** | 1 | 1 | 0 | 0 | 100% | 2.10s |
| **Total / Overall** | **135** | **135** | **0** | **0** | **100%** | **16.80s** |

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
- `test_document_checklist_unit.py`: **6/6 PASS** (Tests Aadhaar and PAN masking algorithm, synthetic document parsing, profile cross-verification `Verified`/`CorrectionRequired` outcomes, and scheme checklist generator).

### 2. Root Pytest Integration Suite (`tests/`)
- `tests/test_phase5_ocr_checklist.py`: **2/2 PASS** (Document upload & parsing, sensitive identifier masking, profile cross-verification, and scheme application readiness checklist API).

### 3. Frontend Flutter Suite (`frontend/test/`)
- `test/unit/ai_chat_model_test.dart`: **2/2 PASS**
- `test/unit/scheme_model_test.dart`: **2/2 PASS**
- `test/unit/auth_state_test.dart`: **6/6 PASS**
- `test/unit/profile_model_test.dart`: **2/2 PASS**
- `test/widget_test.dart`: **1/1 PASS**
- Static Analysis (`flutter analyze`): **0 issues found!**
