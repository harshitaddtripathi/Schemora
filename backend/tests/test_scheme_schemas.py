from app.schemas.scheme import SchemeResponse, SchemeDetailResponse, RecommendationItem, RecommendationResponse


def test_scheme_response_schema():
    payload = {
        "id": "sch-1",
        "slug": "sample-scheme",
        "title": "Sample Scholarship",
        "short_description": "Short description text",
        "provider": "Ministry of Education",
        "jurisdiction": "Central",
        "state": None,
        "benefit_type": "Financial",
        "benefit_summary": "Financial support",
        "implementation_status": "Implemented",
        "is_published": True,
        "application_deadline": "2026-10-31",
    }
    schema = SchemeResponse(**payload)
    assert schema.id == "sch-1"
    assert schema.jurisdiction == "Central"
    assert schema.is_published is True


def test_recommendation_item_schema():
    payload = {
        "scheme_id": "sch-1",
        "scheme_title": "Sample Scholarship",
        "provider": "Ministry of Education",
        "jurisdiction": "Central",
        "benefit_summary": "Financial support",
        "status": "RuleMatched",
        "confidence_score": 1.0,
        "matched_rules_count": 3,
        "unresolved_rules_count": 0,
        "failed_rules_count": 0,
        "unresolved_fields": [],
    }
    item = RecommendationItem(**payload)
    assert item.status == "RuleMatched"
    assert item.confidence_score == 1.0
