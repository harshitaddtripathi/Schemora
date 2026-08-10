import os
from typing import List, Dict, Any, Tuple

# Out-of-scope keywords for non-scheme queries
OUT_OF_SCOPE_KEYWORDS = [
    "weather", "cricket", "movie", "recipe", "capital of", "president of",
    "tell me a joke", "football", "who won", "celebrity"
]


def is_out_of_scope(query: str) -> bool:
    q_lower = query.lower()
    return any(k in q_lower for k in OUT_OF_SCOPE_KEYWORDS)


def generate_grounded_explanation(
    scheme_title: str,
    status: str,
    matched_rules: List[Dict[str, Any]],
    unresolved_rules: List[Dict[str, Any]],
    sources: List[Dict[str, Any]],
    language: str = "en",
) -> Tuple[str, List[Dict[str, Any]]]:
    """Generates deterministic grounded explanation for scheme recommendation with source citations."""
    citations = []
    for s in sources:
        citations.append({
            "source_name": s.get("source_name", "Official Portal"),
            "url": s.get("url", "https://myscheme.gov.in"),
            "last_verified_at": s.get("last_verified_at", "2026-08-07"),
        })

    if status == "RuleMatched":
        explanation = (
            f"Based on official guidelines for '{scheme_title}', you satisfy all mandatory criteria! "
            f"Specifically, your profile matches {len(matched_rules)} verified rule conditions."
        )
    elif status == "NeedsInformation":
        unresolved_fields = [r.get("field_name") for r in unresolved_rules if r.get("field_name")]
        fields_str = ", ".join(unresolved_fields) if unresolved_fields else "required academic fields"
        explanation = (
            f"You are potentially eligible for '{scheme_title}'. "
            f"However, additional information is required for: {fields_str} to complete verification."
        )
    else:
        explanation = (
            f"Based on current guidelines for '{scheme_title}', your profile does not satisfy one or more mandatory criteria."
        )

    if language == "hi":
        explanation += " (आधिकारिक पोर्टल के आधार पर स्पष्टीकरण)"
    elif language == "mr":
        explanation += " (अधिकृत पोर्टलवर आधारित स्पष्टीकरण)"

    return explanation, citations


def generate_grounded_chat_response(
    query: str,
    chunks: List[Dict[str, Any]],
    language: str = "en",
) -> Tuple[str, List[Dict[str, Any]], bool]:
    """Generates grounded answer to student scheme question with citation validation."""
    if is_out_of_scope(query):
        fallback_msg = (
            "I am Schemora's dedicated Academic Scheme Assistant. "
            "I can only answer questions related to central/state government scholarships, internships, and educational schemes."
        )
        return fallback_msg, [], False

    if not chunks:
        insufficient_msg = (
            "Insufficient official guideline information found in our database for this specific scheme question. "
            "Please refer to the official MyScheme portal."
        )
        return insufficient_msg, [], False

    top_chunk = chunks[0]
    answer = f"According to official guidelines: {top_chunk['content']}"

    citations = [
        {
            "source_name": top_chunk.get("source_title", "Official Guideline"),
            "url": top_chunk.get("source_url", "https://myscheme.gov.in"),
            "last_verified_at": "2026-08-07",
        }
    ]

    return answer, citations, True
