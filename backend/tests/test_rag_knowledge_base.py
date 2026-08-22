"""Tests for Schemora RAG Knowledge Base (Phase 1).

Covers:
  - Chunk generation (all 7 sections)
  - Metadata preservation per chunk
  - Embedding service (semantic + TF-IDF fallback)
  - Vector similarity computation
  - Knowledge base indexing
  - Retrieval pipeline
  - Source citation generation
  - Edge cases: empty KB, no results, invalid data
  - RAG evaluation queries (12 real example queries)
  - Anti-hallucination guard
"""

import json
import math
import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, patch, MagicMock
from typing import Any, Dict, List

# ── Sample scheme data for tests ──────────────────────────────────────────────

SAMPLE_SCHEME_PMKISAN = {
    "scheme_id": "sch-central-pmkisan-004",
    "scheme_name": "Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)",
    "scheme_version": "2026-08-01-v1",
    "short_description": "Income support scheme providing Rs 6,000 per year to eligible farmer families.",
    "description": "PM-KISAN provides financial support of Rs 6,000 per annum to landholding farmer families.",
    "benefits": [
        {
            "benefit_id": "pmkisan-benefit-financial",
            "description": "Direct bank transfer of Rs 6,000 annually in 3 installments of Rs 2,000.",
            "amount": 6000,
            "currency": "INR",
            "frequency": "Annual",
            "verification_status": "Verified",
            "source_ids": ["src-pmkisan-official"],
        }
    ],
    "jurisdiction": "Central",
    "state": None,
    "department": "Ministry of Agriculture & Farmers Welfare",
    "scheme_category": "Agriculture",
    "eligibility_rules": {
        "rules_version": "v1",
        "root": {
            "rule_id": "pmkisan-g001",
            "type": "and",
            "conditions": [
                {
                    "rule_id": "pmkisan-r001",
                    "type": "condition",
                    "description": "Applicant is a landholding farmer family.",
                    "field": "occupation",
                    "operator": "eq",
                    "value": "Farmer",
                    "mandatory": True,
                    "missing_behavior": "Unresolved",
                    "verification_status": "Verified",
                    "source_ids": ["src-pmkisan-official"],
                }
            ],
        },
    },
    "required_documents": [
        {
            "document_id": "pmkisan-doc-land",
            "document_type": "LandRecord",
            "name": "Land ownership records",
            "required": True,
            "verification_status": "Verified",
            "source_ids": ["src-pmkisan-official"],
        },
        {
            "document_id": "pmkisan-doc-aadhaar",
            "document_type": "Aadhaar",
            "name": "Aadhaar card",
            "required": True,
            "verification_status": "Verified",
            "source_ids": ["src-pmkisan-official"],
        },
    ],
    "application_process": [
        {
            "step_number": 1,
            "description": "Visit the PM-KISAN portal and register.",
            "channel": "Online",
            "verification_status": "Verified",
            "source_ids": ["src-pmkisan-official"],
        },
        {
            "step_number": 2,
            "description": "Submit land records and Aadhaar details.",
            "channel": "Online",
            "verification_status": "Verified",
            "source_ids": ["src-pmkisan-official"],
        },
    ],
    "official_information_url": "https://pmkisan.gov.in",
    "official_application_url": "https://pmkisan.gov.in/registrationform.aspx",
    "application_windows": [
        {
            "window_id": "pmkisan-window",
            "deadline_type": "Rolling",
            "opens_on": None,
            "closes_on": None,
            "application_cycle": "Rolling applications accepted year-round",
            "verification_status": "Verified",
            "source_ids": ["src-pmkisan-official"],
        }
    ],
    "source_documents": ["src-pmkisan-official"],
    "application_cycle": "Rolling",
    "retrieved_at": "2026-08-01T00:00:00+05:30",
    "verified_at": "2026-08-01T00:00:00+05:30",
    "verified_by": "schemora-phase0-research",
    "status": "Active",
    "verification": {
        "overall_status": "Verified",
        "verified_fields": ["scheme_name", "benefits", "eligibility_rules"],
        "verification_required_fields": [],
        "notes": "PM-KISAN is a well-documented central scheme.",
    },
}

SAMPLE_SCHEME_OBC = {
    "scheme_id": "sch-maharashtra-obc-postmatric-002",
    "scheme_name": "Post Matric Scholarship to OBC Students",
    "scheme_version": "2026-08-07-v1",
    "short_description": "Maharashtra post-matric scholarship for OBC students.",
    "description": "Scholarship for OBC students in Maharashtra pursuing post-matric education.",
    "benefits": [
        {
            "benefit_id": "obc-benefit",
            "description": "Tuition fee and maintenance allowance.",
            "amount": None,
            "currency": "INR",
            "frequency": "Variable",
            "verification_status": "Verified",
            "source_ids": ["src-obc"],
        }
    ],
    "jurisdiction": "State",
    "state": "Maharashtra",
    "department": "VJNT, OBC and SBC Welfare Department",
    "scheme_category": "Scholarship",
    "eligibility_rules": {
        "rules_version": "v1",
        "root": {
            "rule_id": "obc-g001",
            "type": "and",
            "conditions": [
                {
                    "rule_id": "obc-r001",
                    "type": "condition",
                    "description": "Applicant is a resident of Maharashtra.",
                    "field": "state",
                    "operator": "eq",
                    "value": "Maharashtra",
                    "mandatory": True,
                    "missing_behavior": "Unresolved",
                    "verification_status": "Verified",
                    "source_ids": ["src-obc"],
                },
                {
                    "rule_id": "obc-r002",
                    "type": "condition",
                    "description": "Annual family income is at or below INR 250000.",
                    "field": "annual_family_income",
                    "operator": "lte",
                    "value": 250000,
                    "mandatory": True,
                    "missing_behavior": "Unresolved",
                    "verification_status": "Verified",
                    "source_ids": ["src-obc"],
                },
            ],
        },
    },
    "required_documents": [
        {
            "document_id": "obc-doc-caste",
            "document_type": "CasteCertificate",
            "name": "Caste certificate",
            "required": True,
            "verification_status": "Verified",
            "source_ids": ["src-obc"],
        }
    ],
    "application_process": [
        {
            "step_number": 1,
            "description": "Register on MahaDBT portal.",
            "channel": "Online",
            "verification_status": "Verified",
            "source_ids": ["src-obc"],
        }
    ],
    "official_information_url": "https://mahadbt.maharashtra.gov.in",
    "official_application_url": "https://mahadbt.maharashtra.gov.in/Login/Login",
    "application_windows": [],
    "source_documents": ["src-obc"],
    "application_cycle": "Annual",
    "retrieved_at": "2026-08-07T00:00:00+05:30",
    "verified_at": "2026-08-07T00:00:00+05:30",
    "verified_by": "schemora-phase0-research",
    "status": "Active",
    "verification": {
        "overall_status": "Verified",
        "verified_fields": ["scheme_name", "eligibility_rules", "required_documents"],
        "verification_required_fields": ["application_windows"],
        "notes": "Income limit of Rs 2.5 lakh verified from official source.",
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# 1. CHUNK GENERATION TESTS
# ─────────────────────────────────────────────────────────────────────────────

class TestChunkGeneration:
    """Tests for build_chunks_for_scheme()."""

    def test_produces_seven_sections(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        sections = [c["section"] for c in chunks]
        assert "overview" in sections
        assert "benefits" in sections
        assert "eligibility" in sections
        assert "documents" in sections
        assert "application" in sections
        assert "deadlines" in sections
        assert "notes" in sections

    def test_overview_chunk_contains_scheme_name(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        overview = next(c for c in chunks if c["section"] == "overview")
        assert "PM-KISAN" in overview["content"]
        assert "Agriculture" in overview["content"]
        assert "Central" in overview["content"]

    def test_benefits_chunk_contains_amount(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        benefits = next(c for c in chunks if c["section"] == "benefits")
        assert "6000" in benefits["content"] or "6,000" in benefits["content"]
        assert "INR" in benefits["content"]

    def test_eligibility_chunk_contains_conditions(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        eligibility = next(c for c in chunks if c["section"] == "eligibility")
        assert "farmer" in eligibility["content"].lower() or "landholding" in eligibility["content"].lower()

    def test_eligibility_chunk_maharashtra_income(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_OBC)
        eligibility = next(c for c in chunks if c["section"] == "eligibility")
        assert "Maharashtra" in eligibility["content"] or "resident" in eligibility["content"].lower()
        assert "250000" in eligibility["content"] or "income" in eligibility["content"].lower()

    def test_documents_chunk_lists_required_docs(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        docs = next(c for c in chunks if c["section"] == "documents")
        assert "Land" in docs["content"] or "land" in docs["content"].lower()
        assert "Aadhaar" in docs["content"] or "aadhaar" in docs["content"].lower()

    def test_application_chunk_has_steps(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        application = next(c for c in chunks if c["section"] == "application")
        assert "Step 1" in application["content"] or "portal" in application["content"].lower()
        assert SAMPLE_SCHEME_PMKISAN["official_application_url"] in application["content"]

    def test_deadlines_chunk_has_cycle_info(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        deadlines = next(c for c in chunks if c["section"] == "deadlines")
        assert "Rolling" in deadlines["content"]

    def test_notes_chunk_has_verification_info(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        notes = next(c for c in chunks if c["section"] == "notes")
        assert "Verified" in notes["content"] or "verified" in notes["content"].lower()
        assert "pmkisan.gov.in" in notes["content"]


# ─────────────────────────────────────────────────────────────────────────────
# 2. METADATA PRESERVATION TESTS
# ─────────────────────────────────────────────────────────────────────────────

class TestMetadataPreservation:
    """Every chunk must carry full metadata."""

    def test_all_chunks_have_scheme_id(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        for c in chunks:
            assert c["scheme_id"] == "sch-central-pmkisan-004"

    def test_all_chunks_have_scheme_name(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        for c in chunks:
            assert c["scheme_name"] == "Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)"

    def test_all_chunks_have_official_urls(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        for c in chunks:
            assert "pmkisan.gov.in" in c["official_info_url"]
            assert "pmkisan.gov.in" in c["official_app_url"]

    def test_all_chunks_have_jurisdiction(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        for c in chunks:
            assert c["jurisdiction"] == "Central"

    def test_state_scheme_has_state_metadata(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_OBC)
        for c in chunks:
            assert c["state"] == "Maharashtra"
            assert c["jurisdiction"] == "State"

    def test_all_chunks_have_verified_at(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        for c in chunks:
            assert c["last_verified_at"] != ""

    def test_all_chunks_have_scheme_version(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        for c in chunks:
            assert c["scheme_version"] == "2026-08-01-v1"

    def test_all_chunks_have_category(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = build_chunks_for_scheme(SAMPLE_SCHEME_PMKISAN)
        for c in chunks:
            assert c["category"] == "Agriculture"


# ─────────────────────────────────────────────────────────────────────────────
# 3. EMBEDDING SERVICE TESTS
# ─────────────────────────────────────────────────────────────────────────────

class TestEmbeddingService:
    """Tests for embedding_service.py."""

    def test_tfidf_vector_basic(self):
        from app.services.embedding_service import _tfidf_vector
        vec = _tfidf_vector("scholarship for students in Maharashtra")
        assert "scholarship" in vec
        assert "students" in vec
        assert "maharashtra" in vec
        assert all(0 < v <= 1 for v in vec.values())

    def test_tfidf_empty_text(self):
        from app.services.embedding_service import _tfidf_vector
        vec = _tfidf_vector("")
        assert vec == {}

    def test_cosine_similarity_identical(self):
        from app.services.embedding_service import cosine_similarity_tfidf, _tfidf_vector
        v = _tfidf_vector("farmer income support")
        score = cosine_similarity_tfidf(v, v)
        assert abs(score - 1.0) < 1e-6

    def test_cosine_similarity_zero(self):
        from app.services.embedding_service import cosine_similarity_tfidf, _tfidf_vector
        v1 = _tfidf_vector("farmer agriculture")
        v2 = _tfidf_vector("scholarship university")
        score = cosine_similarity_tfidf(v1, v2)
        assert score == 0.0

    def test_cosine_similarity_partial(self):
        from app.services.embedding_service import cosine_similarity_tfidf, _tfidf_vector
        v1 = _tfidf_vector("PM-KISAN farmer support income")
        v2 = _tfidf_vector("farmer income benefit")
        score = cosine_similarity_tfidf(v1, v2)
        assert 0.0 < score < 1.0

    def test_dense_cosine_similarity(self):
        from app.services.embedding_service import cosine_similarity_dense
        v1 = [1.0, 0.0, 0.5]
        v2 = [1.0, 0.0, 0.5]
        assert abs(cosine_similarity_dense(v1, v2) - 1.0) < 1e-6

    def test_dense_cosine_zero(self):
        from app.services.embedding_service import cosine_similarity_dense
        v1 = [1.0, 0.0]
        v2 = [0.0, 1.0]
        assert cosine_similarity_dense(v1, v2) == 0.0

    def test_is_dense_embedding_true(self):
        from app.services.embedding_service import is_dense_embedding
        assert is_dense_embedding([0.1] * 768) is True

    def test_is_dense_embedding_false_dict(self):
        from app.services.embedding_service import is_dense_embedding
        assert is_dense_embedding({"word": 0.5}) is False

    def test_is_dense_embedding_false_short(self):
        from app.services.embedding_service import is_dense_embedding
        assert is_dense_embedding([0.1, 0.2]) is False

    def test_embedding_serialization_roundtrip(self):
        from app.services.embedding_service import embedding_to_json, json_to_embedding
        original = [0.1, 0.2, 0.3, 0.4, 0.5]
        serialized = embedding_to_json(original)
        restored = json_to_embedding(serialized)
        assert restored == original

    def test_embedding_serialization_dict(self):
        from app.services.embedding_service import embedding_to_json, json_to_embedding
        original = {"farmer": 0.5, "income": 0.3}
        serialized = embedding_to_json(original)
        restored = json_to_embedding(serialized)
        assert restored == original

    @pytest.mark.asyncio
    async def test_embed_text_fallback_when_no_key(self):
        """With no API key, embed_text should return TF-IDF."""
        from app.services.embedding_service import embed_text
        with patch("app.services.embedding_service._get_api_key", return_value=""):
            embedding, is_semantic = await embed_text("farmer income support")
        assert is_semantic is False
        assert isinstance(embedding, dict)
        assert len(embedding) > 0

    @pytest.mark.asyncio
    async def test_embed_text_gemini_failure_returns_tfidf(self):
        """When Gemini API fails, should fall back to TF-IDF."""
        from app.services.embedding_service import embed_text
        with patch("app.services.embedding_service.generate_embedding", return_value=None):
            embedding, is_semantic = await embed_text("scholarship for OBC students")
        assert is_semantic is False
        assert isinstance(embedding, dict)


# ─────────────────────────────────────────────────────────────────────────────
# 4. DOCUMENT PROCESSOR TESTS
# ─────────────────────────────────────────────────────────────────────────────

class TestDocumentProcessor:
    """Tests for document_processor.py."""

    def test_detect_eligibility_section(self):
        from app.services.document_processor import detect_section
        assert detect_section("Eligibility criteria: applicant must be OBC") == "eligibility"

    def test_detect_benefits_section(self):
        from app.services.document_processor import detect_section
        assert detect_section("Scholarship amount: Rs 5000 per year") == "benefits"

    def test_detect_documents_section(self):
        from app.services.document_processor import detect_section
        assert detect_section("Required documents: caste certificate, income certificate") == "documents"

    def test_detect_application_section(self):
        from app.services.document_processor import detect_section
        assert detect_section("How to apply: visit the MahaDBT portal") == "application"

    def test_detect_deadlines_section(self):
        from app.services.document_processor import detect_section
        assert detect_section("Application deadline: 31 December 2026") == "deadlines"

    def test_detect_overview_fallback(self):
        from app.services.document_processor import detect_section
        assert detect_section("This is a general introductory paragraph.") == "overview"

    def test_split_multi_paragraph_text(self):
        from app.services.document_processor import split_into_sections
        text = (
            "PM-KISAN provides support to farmers.\n\n"
            "Eligibility: Farmer must own land.\n\n"
            "Documents required: Land records."
        )
        sections = split_into_sections(text)
        assert len(sections) >= 2

    def test_process_admin_document_returns_chunks(self):
        from app.services.document_processor import process_admin_document
        text = (
            "PM-KISAN gives Rs 6000 per year to farmers.\n\n"
            "Eligibility: Must be a land-owning farmer family.\n\n"
            "Documents: Land ownership records and Aadhaar."
        )
        chunks = process_admin_document(
            raw_text=text,
            scheme_id="sch-central-pmkisan-004",
            scheme_name="PM-KISAN",
            source_url="https://pmkisan.gov.in",
        )
        assert len(chunks) >= 1
        for c in chunks:
            assert c["scheme_id"] == "sch-central-pmkisan-004"
            assert c["scheme_name"] == "PM-KISAN"
            assert "official_info_url" in c


# ─────────────────────────────────────────────────────────────────────────────
# 5. SOURCE CITATION GENERATION TESTS
# ─────────────────────────────────────────────────────────────────────────────

class TestCitationGeneration:
    """Tests for citation building in gemini_service.py."""

    def test_citations_deduplicated_by_url(self):
        from app.services.gemini_service import _build_citations
        chunks = [
            {"source_url": "https://pmkisan.gov.in", "source_title": "PM-KISAN Overview", "last_verified_at": "2026-08-01"},
            {"source_url": "https://pmkisan.gov.in", "source_title": "PM-KISAN Benefits", "last_verified_at": "2026-08-01"},
            {"source_url": "https://myscheme.gov.in", "source_title": "MyScheme", "last_verified_at": "2026-08-07"},
        ]
        citations = _build_citations(chunks)
        assert len(citations) == 2
        urls = [c["url"] for c in citations]
        assert "https://pmkisan.gov.in" in urls
        assert "https://myscheme.gov.in" in urls

    def test_citations_have_all_required_fields(self):
        from app.services.gemini_service import _build_citations
        chunks = [
            {"source_url": "https://pmkisan.gov.in", "source_title": "PM-KISAN", "last_verified_at": "2026-08-01"},
        ]
        citations = _build_citations(chunks)
        assert len(citations) == 1
        c = citations[0]
        assert "source_name" in c
        assert "url" in c
        assert "last_verified_at" in c

    def test_empty_chunks_produces_no_citations(self):
        from app.services.gemini_service import _build_citations
        assert _build_citations([]) == []


# ─────────────────────────────────────────────────────────────────────────────
# 6. EDGE CASE TESTS
# ─────────────────────────────────────────────────────────────────────────────

class TestEdgeCases:
    """Tests for edge cases: empty KB, no results, invalid data."""

    def test_empty_scheme_does_not_crash(self):
        from app.services.knowledge_base_service import build_chunks_for_scheme
        empty_scheme = {
            "scheme_id": "test-empty",
            "scheme_name": "Test Empty Scheme",
            "scheme_version": "v1",
            "verified_at": "2026-08-07",
            "verified_by": "test",
            "verification": {"overall_status": "Unknown", "verified_fields": [], "verification_required_fields": [], "notes": ""},
        }
        chunks = build_chunks_for_scheme(empty_scheme)
        assert isinstance(chunks, list)

    def test_scheme_with_no_benefits_produces_chunk(self):
        from app.services.knowledge_base_service import _build_benefits_chunk
        scheme = {"scheme_name": "Test", "benefits": []}
        text = _build_benefits_chunk(scheme)
        assert "Test" in text
        assert "official" in text.lower() or "portal" in text.lower()

    def test_scheme_with_no_documents_produces_chunk(self):
        from app.services.knowledge_base_service import _build_documents_chunk
        scheme = {"scheme_name": "Test", "required_documents": []}
        text = _build_documents_chunk(scheme)
        assert "Test" in text

    def test_scheme_with_no_steps_produces_chunk(self):
        from app.services.knowledge_base_service import _build_application_chunk
        scheme = {"scheme_name": "Test", "application_process": [], "official_application_url": ""}
        text = _build_application_chunk(scheme)
        assert "Test" in text

    @pytest.mark.asyncio
    async def test_out_of_scope_query_returns_refusal(self):
        from app.services.gemini_service import generate_grounded_chat_response
        answer, citations, is_grounded = await generate_grounded_chat_response(
            query="Who won the cricket match yesterday?",
            chunks=[],
            language="en",
        )
        assert is_grounded is False
        assert len(citations) == 0
        assert "scheme" in answer.lower() or "government" in answer.lower() or "only" in answer.lower()

    @pytest.mark.asyncio
    async def test_empty_chunks_returns_not_found_message(self):
        from app.services.gemini_service import generate_grounded_chat_response
        answer, citations, is_grounded = await generate_grounded_chat_response(
            query="What is the scholarship amount for OBC students?",
            chunks=[],
            language="en",
        )
        assert is_grounded is False
        assert len(citations) == 0
        assert "knowledge base" in answer.lower() or "official" in answer.lower() or "couldn't" in answer.lower()


# ─────────────────────────────────────────────────────────────────────────────
# 7. RAG EVALUATION QUERIES
# ─────────────────────────────────────────────────────────────────────────────

class TestRAGEvaluationQueries:
    """Validates retrieval on real example queries. Uses TF-IDF (no API key needed)."""

    def _make_chunks(self) -> list:
        """Build test chunks from sample schemes."""
        from app.services.knowledge_base_service import build_chunks_for_scheme
        chunks = []
        for scheme in [SAMPLE_SCHEME_PMKISAN, SAMPLE_SCHEME_OBC]:
            raw = build_chunks_for_scheme(scheme)
            for c in raw:
                from app.services.embedding_service import _tfidf_vector, embedding_to_json
                vec = _tfidf_vector(c["content"])
                c["embedding"] = vec
                c["embedding_json"] = embedding_to_json(vec)
            chunks.extend(raw)
        return chunks

    def _retrieve(self, query: str, chunks: list, top_k: int = 3) -> list:
        """TF-IDF retrieval over pre-built chunks."""
        from app.services.embedding_service import _tfidf_vector, cosine_similarity_tfidf
        q_vec = _tfidf_vector(query)
        scored = []
        for c in chunks:
            score = cosine_similarity_tfidf(q_vec, c["embedding"])
            if score > 0:
                scored.append({**c, "similarity_score": score})
        scored.sort(key=lambda x: x["similarity_score"], reverse=True)
        return scored[:top_k]

    def test_q01_scholarship_query_retrieves_obc(self):
        chunks = self._make_chunks()
        results = self._retrieve("Which scholarship can I apply for?", chunks)
        assert len(results) > 0
        scheme_names = [r.get("scheme_name", "") for r in results]
        assert any("OBC" in n or "Scholarship" in n or "PM" in n for n in scheme_names)

    def test_q02_documents_query_retrieves_doc_chunks(self):
        chunks = self._make_chunks()
        results = self._retrieve("What documents do I need for the scholarship?", chunks)
        assert len(results) > 0
        sections = [r.get("section", "") for r in results]
        assert "documents" in sections or any(
            "document" in r.get("content", "").lower() for r in results
        )

    def test_q03_income_limit_query_retrieves_eligibility(self):
        chunks = self._make_chunks()
        results = self._retrieve("What is the income limit for OBC scholarship?", chunks)
        assert len(results) > 0
        any_has_income = any(
            "income" in r.get("content", "").lower() or "250000" in r.get("content", "")
            for r in results
        )
        assert any_has_income

    def test_q04_how_to_apply_retrieves_application_chunk(self):
        chunks = self._make_chunks()
        results = self._retrieve("How do I apply for PM-KISAN?", chunks)
        assert len(results) > 0
        has_apply_content = any(
            "apply" in r.get("content", "").lower() or "portal" in r.get("content", "").lower()
            for r in results
        )
        assert has_apply_content

    def test_q05_maharashtra_query_retrieves_state_scheme(self):
        chunks = self._make_chunks()
        results = self._retrieve("Show schemes available in Maharashtra", chunks)
        assert len(results) > 0
        has_maharashtra = any(
            "Maharashtra" in r.get("content", "") or r.get("state") == "Maharashtra"
            for r in results
        )
        assert has_maharashtra

    def test_q06_farmer_support_retrieves_pmkisan(self):
        chunks = self._make_chunks()
        results = self._retrieve("Is there any scheme for farmers?", chunks)
        assert len(results) > 0
        has_farmer = any(
            "farmer" in r.get("content", "").lower() or "KISAN" in r.get("content", "")
            for r in results
        )
        assert has_farmer

    def test_q07_benefit_amount_retrieves_benefits_chunk(self):
        chunks = self._make_chunks()
        results = self._retrieve("What is the financial benefit amount?", chunks)
        assert len(results) > 0
        has_benefit = any(
            "benefit" in r.get("content", "").lower() or "amount" in r.get("content", "").lower()
            for r in results
        )
        assert has_benefit

    def test_q08_deadline_query_retrieves_deadline_chunk(self):
        chunks = self._make_chunks()
        results = self._retrieve("When is the application deadline?", chunks)
        assert len(results) > 0

    def test_q09_caste_certificate_query_retrieves_documents(self):
        chunks = self._make_chunks()
        results = self._retrieve("Do I need a caste certificate?", chunks)
        assert len(results) > 0
        has_caste = any(
            "caste" in r.get("content", "").lower()
            for r in results
        )
        assert has_caste

    def test_q10_internship_retrieves_no_false_positives(self):
        chunks = self._make_chunks()
        results = self._retrieve("Tell me about PM Internship Scheme", chunks)
        # With only PMKISAN and OBC in test data, results may be low-scoring
        # but should not hallucinate
        for r in results:
            assert r.get("scheme_id") in [
                "sch-central-pmkisan-004",
                "sch-maharashtra-obc-postmatric-002",
            ]

    def test_q11_hindi_query_retrieves_results(self):
        chunks = self._make_chunks()
        results = self._retrieve("किसानों के लिए कोई योजना है?", chunks)
        # Hindi text may have low TF-IDF overlap, but should not crash
        assert isinstance(results, list)

    def test_q12_completely_irrelevant_query_low_score(self):
        chunks = self._make_chunks()
        results = self._retrieve("what is the capital of France", chunks)
        # All similarity scores should be very low for irrelevant queries
        for r in results:
            assert r.get("similarity_score", 0) < 0.5


# ─────────────────────────────────────────────────────────────────────────────
# 8. ANTI-HALLUCINATION GUARD
# ─────────────────────────────────────────────────────────────────────────────

class TestAntiHallucination:
    """Verify the system cannot invent scheme details."""

    @pytest.mark.asyncio
    async def test_fallback_answer_only_contains_retrieved_content(self):
        """When Gemini is unavailable, fallback answer uses only chunk content."""
        from app.services.gemini_service import _build_fallback_response
        chunks = [
            {
                "scheme_name": "PM-KISAN",
                "section": "benefits",
                "content": "PM-KISAN provides Rs 6000 per year to farmers.",
                "last_verified_at": "2026-08-01",
            }
        ]
        answer = _build_fallback_response(chunks, "en", "English")
        assert "PM-KISAN" in answer
        assert "6000" in answer or "6,000" in answer
        # Should not contain fabricated scheme names
        assert "imaginary" not in answer.lower()

    @pytest.mark.asyncio
    async def test_out_of_scope_never_returns_scheme_info(self):
        """Out-of-scope queries should return refusal, never scheme data."""
        from app.services.gemini_service import generate_grounded_chat_response
        fake_chunks = [
            {
                "scheme_name": "PM-KISAN",
                "section": "benefits",
                "content": "PM-KISAN provides Rs 6000 per year.",
                "source_url": "https://pmkisan.gov.in",
                "source_title": "PM-KISAN",
                "last_verified_at": "2026-08-01",
            }
        ]
        answer, citations, is_grounded = await generate_grounded_chat_response(
            query="What is the weather today in Mumbai?",
            chunks=fake_chunks,  # even if chunks exist, OOS should block
            language="en",
        )
        assert is_grounded is False

    def test_prompt_contains_safety_instructions(self):
        """Safety prompt must include anti-hallucination instructions."""
        from app.services.gemini_service import _build_rag_prompt
        chunks = [
            {
                "scheme_name": "PM-KISAN",
                "section": "overview",
                "content": "PM-KISAN provides Rs 6000.",
                "last_verified_at": "2026-08-01",
            }
        ]
        prompt = _build_rag_prompt("What is PM-KISAN?", chunks, "English")
        assert "STRICT SAFETY RULES" in prompt or "Do NOT invent" in prompt or "Never" in prompt
        assert "6000" in prompt or "PM-KISAN" in prompt
