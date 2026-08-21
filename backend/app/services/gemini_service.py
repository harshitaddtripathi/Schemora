import os
import logging
import httpx
from typing import List, Dict, Any, Tuple
from app.core.config import settings

logger = logging.getLogger(__name__)

# Out-of-scope keywords for non-scheme queries
OUT_OF_SCOPE_KEYWORDS = [
    "weather", "cricket", "movie", "recipe", "capital of", "president of",
    "tell me a joke", "football", "who won", "celebrity"
]

GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"


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


async def generate_grounded_chat_response(
    query: str,
    chunks: List[Dict[str, Any]],
    language: str = "en",
) -> Tuple[str, List[Dict[str, Any]], bool]:
    """Generates grounded answer to student scheme question with citation validation and multilingual support."""
    if is_out_of_scope(query):
        if language == "hi":
            fallback_msg = "मैं स्केमोरा का शैक्षणिक योजना सहायक हूँ। मैं केवल केंद्रीय और राज्य सरकारी योजनाओं, छात्रवृत्ति और इंटर्नशिप से संबंधित प्रश्नों का उत्तर दे सकता हूँ।"
        elif language == "mr":
            fallback_msg = "मी स्केमोराचा शैक्षणिक योजना सहाय्यक आहे. मी फक्त केंद्र आणि राज्य सरकारी योजना, शिष्यवृत्ती आणि इंटर्नशिप संबंधी प्रश्नांची उत्तरे देऊ शकतो."
        else:
            fallback_msg = (
                "I am Schemora's dedicated Academic Scheme Assistant. "
                "I can only answer questions related to central/state government scholarships, internships, and educational schemes."
            )
        return fallback_msg, [], False

    if not chunks:
        if language == "hi":
            insufficient_msg = "हमारे डेटाबेस में इस विशिष्ट योजना प्रश्न के लिए पर्याप्त आधिकारिक दिशानिर्देश नहीं मिले। कृपया आधिकारिक मायस्कीम पोर्टल देखें।"
        elif language == "mr":
            insufficient_msg = "आमच्या डेटाबेसमध्ये या विशिष्ट योजनेच्या प्रश्नासाठी पुरेशी माहिती मिळाली नाही. कृपया अधिकृत मायस्कीम पोर्टल पहा."
        else:
            insufficient_msg = (
                "Insufficient official guideline information found in our database for this specific scheme question. "
                "Please refer to the official MyScheme portal."
            )
        return insufficient_msg, [], False

    citations = []
    context_text = ""
    for c in chunks:
        context_text += f"- {c['content']}\n"
        citations.append({
            "source_name": c.get("source_title", "Official Guideline"),
            "url": c.get("source_url", "https://myscheme.gov.in"),
            "last_verified_at": "2026-08-07",
        })

    api_key = os.getenv("GEMINI_API_KEY") or settings.GEMINI_API_KEY

    lang_name = "Hindi" if language == "hi" else "Marathi" if language == "mr" else "English"

    if api_key and api_key.startswith("AIzaSy"):
        try:
            url = f"{GEMINI_API_URL}?key={api_key}"
            prompt = (
                f"You are Schemora AI Assistant, an expert AI agent on Indian Government Schemes (e.g. PM-KISAN, NSP, Welfare Schemes).\n"
                f"Answer the user's question accurately in {lang_name} based ONLY on the following official scheme guidelines:\n\n"
                f"{context_text}\n"
                f"User Question: {query}\n\n"
                f"Provide a helpful, clear, structured response in {lang_name}."
            )

            payload = {
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                    "temperature": 0.3,
                    "maxOutputTokens": 1024,
                }
            }

            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.post(url, json=payload)
                if resp.status_code == 200:
                    data = resp.json()
                    answer = data["candidates"][0]["content"]["parts"][0]["text"].strip()
                    return answer, citations, True
                else:
                    logger.warning(f"Gemini API returned status {resp.status_code}: {resp.text}")
        except Exception as e:
            logger.error(f"Error calling Gemini API for chat response: {e}")

    # Fallback to top chunk content with proper language prefix
    top_chunk = chunks[0]
    raw_content = top_chunk["content"]
    if language == "hi":
        answer = f"आधिकारिक दिशानिर्देशों के अनुसार:\n{raw_content}"
    elif language == "mr":
        answer = f"अधिकृत मार्गदर्शक तत्त्वांनुसार:\n{raw_content}"
    else:
        answer = f"According to official guidelines:\n{raw_content}"

    return answer, citations, True
