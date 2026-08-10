import pytest
from app.services.rag_service import chunk_text, compute_tfidf_vector, cosine_similarity
from app.services.gemini_service import is_out_of_scope, generate_grounded_explanation, generate_grounded_chat_response
from app.schemas.ai import AIExplanationRequest, AIExplanationResponse, AIChatRequest, AIChatResponse, SourceCitation


def test_chunk_text_algorithm():
    sample_text = "Word " * 200  # 1000 characters
    chunks = chunk_text(sample_text, chunk_size=500, overlap=50)

    assert len(chunks) >= 2
    assert len(chunks[0]) <= 500


def test_tfidf_vector_and_cosine_similarity():
    text1 = "Scholarship for college students pursuing undergraduate degrees."
    text2 = "Undergraduate scholarship assistance for eligible students."
    text3 = "Unrelated text about international space exploration."

    v1 = compute_tfidf_vector(text1)
    v2 = compute_tfidf_vector(text2)
    v3 = compute_tfidf_vector(text3)

    sim12 = cosine_similarity(v1, v2)
    sim13 = cosine_similarity(v1, v3)

    assert sim12 > sim13
    assert sim12 > 0.3


def test_out_of_scope_query_detection():
    assert is_out_of_scope("Who won the cricket match yesterday?") is True
    assert is_out_of_scope("What is the weather forecast for tomorrow?") is True
    assert is_out_of_scope("What is the income eligibility for CSSS scholarship?") is False


def test_generate_grounded_explanation_formatting():
    sources = [{"source_name": "NSP Portal", "url": "https://scholarships.gov.in", "last_verified_at": "2026-08-07"}]
    matched = [{"field_name": "state"}]

    explanation, citations = generate_grounded_explanation(
        scheme_title="CSSS Scholarship",
        status="RuleMatched",
        matched_rules=matched,
        unresolved_rules=[],
        sources=sources,
        language="en",
    )

    assert "CSSS Scholarship" in explanation
    assert "satisfy all mandatory criteria" in explanation
    assert len(citations) == 1
    assert citations[0]["source_name"] == "NSP Portal"


def test_ai_schemas_validation():
    req = AIExplanationRequest(scheme_id="sch-1", language="en")
    assert req.scheme_id == "sch-1"

    cit = SourceCitation(source_name="MyScheme", url="https://myscheme.gov.in")
    res = AIExplanationResponse(scheme_id="sch-1", explanation="Eligible", citations=[cit])
    assert len(res.citations) == 1
