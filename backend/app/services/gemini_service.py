"""Gemini AI Service — Schemora (upgraded for RAG Phase 1).

Responsibilities:
  - generate_grounded_explanation(): deterministic explanation for scheme eligibility
  - generate_grounded_chat_response(): RAG-powered Q&A with safety guardrails

Safety Rules enforced in every prompt:
  1. Answer ONLY based on retrieved context. Never invent schemes or facts.
  2. If info is not in context, say so clearly.
  3. Never fabricate benefit amounts, deadlines, or application links.
  4. Always cite which source the answer comes from.
  5. Distinguish: verified info vs. needs-verification info.
"""

import os
import logging
import httpx
from typing import Any, Dict, List, Optional, Tuple

from app.core.config import settings

logger = logging.getLogger(__name__)

GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

OUT_OF_SCOPE_KEYWORDS = [
    "weather", "cricket", "movie", "recipe", "capital of", "president of",
    "tell me a joke", "football", "who won", "celebrity", "stock price",
    "bitcoin", "gaming", "sports score",
]

LANG_NAMES = {
    "hi": "Hindi", "mr": "Marathi", "bn": "Bengali", "te": "Telugu",
    "ta": "Tamil", "gu": "Gujarati", "kn": "Kannada", "ml": "Malayalam",
    "pa": "Punjabi", "or": "Odia", "as": "Assamese", "ur": "Urdu",
    "sa": "Sanskrit", "ne": "Nepali", "sd": "Sindhi", "kok": "Konkani",
    "mai": "Maithili", "doi": "Dogri",
}

LANG_FALLBACK_MESSAGES = {
    "hi": "मैं स्केमोराचा शैक्षणिक योजना सहायक हूँ। मैं केवल केंद्र और राज्य सरकार की योजनाओं, छात्रवृत्ति और इंटर्नशिप से संबंधित प्रश्नों का उत्तर देता हूँ।",
    "mr": "मी स्केमोराचा शैक्षणिक योजना सहाय्यक आहे. मी फक्त केंद्र आणि राज्य सरकारी योजना, शिष्यवृत्ती आणि इंटर्नशिप संबंधी प्रश्नांची उत्तरे देतो.",
    "bn": "আমি সরকারি প্রকল্প সম্পর্কে প্রশ্নের উত্তর দিতে পারি।",
    "te": "నేను ప్రభుత్వ పథకాల గురించి మాత్రమే సమాచారం ఇస్తాను.",
    "ta": "நான் அரசு திட்டங்கள் பற்றிய கேள்விகளுக்கு மட்டுமே பதிலளிப்பேன்.",
    "gu": "હું ફક્ત સરકારી યોજનાઓ વિશે જ પ્રશ્નોના જવાબ આપું છું.",
    "kn": "ನಾನು ಸರ್ಕಾರಿ ಯೋಜನೆಗಳ ಬಗ್ಗೆ ಮಾತ್ರ ಮಾಹಿತಿ ನೀಡಬಲ್ಲೆ.",
    "ml": "ഞാൻ സർക്കാർ പദ്ധതികളെ കുറിച്ചുള്ള ചോദ്യങ്ങൾക്ക് മാത്രം ഉത്തരം നൽകുന്നു.",
    "pa": "ਮੈਂ ਸਿਰਫ਼ ਸਰਕਾਰੀ ਯੋਜਨਾਵਾਂ ਬਾਰੇ ਸਵਾਲਾਂ ਦੇ ਜਵਾਬ ਦਿੰਦਾ ਹਾਂ।",
}

NOT_FOUND_MESSAGES = {
    "hi": "इस प्रश्न के लिए हमारे वर्तमान ज्ञान आधार में पर्याप्त सत्यापित जानकारी नहीं मिली। कृपया आधिकारिक सरकारी पोर्टल देखें।",
    "mr": "या प्रश्नासाठी आमच्या सध्याच्या ज्ञान आधारात पुरेशी सत्यापित माहिती आढळली नाही. कृपया अधिकृत सरकारी पोर्टल पहा.",
}


def _get_api_key() -> str:
    return os.getenv("GEMINI_API_KEY") or settings.GEMINI_API_KEY or ""


def _get_generation_model() -> str:
    return getattr(settings, "GEMINI_GENERATION_MODEL", "gemini-2.5-flash")


def _build_headers_and_url(api_key: str, model: str) -> Tuple[str, Dict[str, str]]:
    """Build the correct URL and headers based on key type."""
    base = f"{GEMINI_BASE_URL}/{model}:generateContent"
    if api_key.startswith("AIzaSy"):
        return f"{base}?key={api_key}", {"Content-Type": "application/json"}
    else:
        return base, {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        }


def is_out_of_scope(query: str) -> bool:
    q_lower = query.lower()
    return any(k in q_lower for k in OUT_OF_SCOPE_KEYWORDS)


# ── Grounded explanation (deterministic — for scheme recommendations) ──────────

def generate_grounded_explanation(
    scheme_title: str,
    status: str,
    matched_rules: List[Dict[str, Any]],
    unresolved_rules: List[Dict[str, Any]],
    sources: List[Dict[str, Any]],
    language: str = "en",
) -> Tuple[str, List[Dict[str, Any]]]:
    """Deterministic grounded explanation for scheme recommendation results."""
    citations = [
        {
            "source_name": s.get("source_name", "Official Portal"),
            "url": s.get("url", "https://myscheme.gov.in"),
            "last_verified_at": s.get("last_verified_at", "2026-08-07"),
        }
        for s in sources
    ]

    if status == "RuleMatched":
        explanation = (
            f"Based on official guidelines for '{scheme_title}', you satisfy all "
            f"mandatory criteria! Your profile matches {len(matched_rules)} verified conditions."
        )
    elif status == "NeedsInformation":
        fields = [r.get("field_name") for r in unresolved_rules if r.get("field_name")]
        fields_str = ", ".join(fields) if fields else "required fields"
        explanation = (
            f"You are potentially eligible for '{scheme_title}'. "
            f"Additional information is needed for: {fields_str}."
        )
    else:
        explanation = (
            f"Based on current guidelines for '{scheme_title}', "
            f"your profile does not satisfy one or more mandatory criteria."
        )

    lang_suffix = {
        "hi": " (आधिकारिक दिशानिर्देशों के आधार पर)",
        "mr": " (अधिकृत मार्गदर्शक तत्त्वांनुसार)",
        "bn": " (সরকারি নির্দেশিকা অনুযায়ী)",
        "te": " (అధికారిక మార్గదర్శకాల ఆధారంగా)",
        "ta": " (அதிகாரப்பூர்வ வழிகாட்டுதல்களின் அடிப்படையில்)",
    }.get(language, "")

    return explanation + lang_suffix, citations


# ── Grounded RAG chat response ────────────────────────────────────────────────

def _build_rag_prompt(
    query: str,
    chunks: List[Dict[str, Any]],
    lang_name: str,
    eligibility_context: Optional[str] = None,
) -> str:
    """Build a safety-first grounded prompt for Gemini."""

    # Build context block from chunks
    context_lines = []
    for i, c in enumerate(chunks, 1):
        scheme_name = c.get("scheme_name", "")
        section = c.get("section", "")
        content = c.get("content", "")
        verified = c.get("last_verified_at", "")
        context_lines.append(
            f"[Source {i}] {scheme_name} ({section.title()}) — Verified: {verified}\n{content}"
        )
    context_text = "\n\n".join(context_lines)

    eligibility_section = ""
    if eligibility_context:
        eligibility_section = f"""
ELIGIBILITY RESULT (from deterministic rule engine — do NOT override):
{eligibility_context}
"""

    prompt = f"""You are Schemora AI Assistant, a trusted expert on Indian Government Schemes (scholarships, internships, welfare, agriculture, skill development).

STRICT SAFETY RULES — follow without exception:
1. Answer ONLY using the verified scheme information provided below. Do NOT invent facts.
2. If the answer is not found in the context, say: "I couldn't find verified information for this in the current Schemora knowledge base. Please check the official government source."
3. Never fabricate: scheme names, benefit amounts, income limits, deadlines, or application links.
4. Always indicate which source each piece of information comes from.
5. Clearly distinguish: ✓ Verified information vs. ? Information requiring verification.
6. If a field says "requires verification", say so honestly.
7. Respond in {lang_name}. Keep scheme names and official URLs in their original form.
8. Be friendly, clear, and helpful. Use simple language. Guide the user step by step.
9. If the user's question is about eligibility, explain the rules simply — do NOT make a judgment call. Refer to the eligibility result below.

VERIFIED SCHEME KNOWLEDGE BASE:
{context_text}
{eligibility_section}

USER QUESTION: {query}

RESPONSE FORMAT:
- Give a clear, helpful answer in {lang_name}
- For scheme-specific info: cite the source (e.g., "According to PM-KISAN official guidelines...")
- End with 2-3 suggested follow-up questions the user might want to ask
- Format follow-ups as: "You might also want to ask: ..."
"""
    return prompt


async def _call_gemini(prompt: str, api_key: str, model: str) -> Optional[str]:
    """Call Gemini generate API. Returns text or None on failure."""
    url, headers = _build_headers_and_url(api_key, model)
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.2,  # Low temperature for factual accuracy
            "maxOutputTokens": 1500,
            "topP": 0.8,
        },
    }
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.post(url, json=payload, headers=headers)
        if resp.status_code == 200:
            data = resp.json()
            return data["candidates"][0]["content"]["parts"][0]["text"].strip()
        else:
            logger.warning(f"Gemini generate API error {resp.status_code}: {resp.text[:300]}")
            return None
    except Exception as e:
        logger.error(f"Gemini generate call failed: {e}")
        return None


def _build_citations(chunks: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Build deduplicated citation list from retrieved chunks."""
    seen_urls = set()
    citations = []
    for c in chunks:
        url = c.get("source_url", "https://myscheme.gov.in")
        if url not in seen_urls:
            seen_urls.add(url)
            citations.append({
                "source_name": c.get("source_title", "Official Government Source"),
                "url": url,
                "last_verified_at": c.get("last_verified_at", "2026-08-07"),
            })
    return citations


def _build_fallback_response(
    chunks: List[Dict[str, Any]],
    language: str,
    lang_name: str,
) -> str:
    """Build a readable fallback when Gemini is unavailable."""
    if not chunks:
        msg = NOT_FOUND_MESSAGES.get(language, (
            "I couldn't find verified information for this in the current Schemora "
            "knowledge base. Please check the official government source."
        ))
        return msg

    parts = []
    lang_prefix = {
        "hi": "आधिकारिक दिशानिर्देशों के अनुसार:",
        "mr": "अधिकृत मार्गदर्शक तत्त्वांनुसार:",
        "bn": "আনুষ্ঠানিক নির্দেশিকা অনুযায়ী:",
        "te": "అధికారిక మార్గదర్శకాల ప్రకారం:",
        "ta": "அதிகாரப்பூர்வ வழிகாட்டுதல்களின்படி:",
    }.get(language, "According to official guidelines:")

    parts.append(parts)
    for c in chunks[:3]:
        name = c.get("scheme_name", "")
        section = c.get("section", "")
        content = c.get("content", "")
        parts.append(f"\n📌 {name} ({section.title()}):\n{content[:600]}")

    return f"{lang_prefix}\n" + "\n".join(str(p) for p in parts[1:])


async def generate_grounded_chat_response(
    query: str,
    chunks: List[Dict[str, Any]],
    language: str = "en",
    eligibility_context: Optional[str] = None,
) -> Tuple[str, List[Dict[str, Any]], bool]:
    """Generate a RAG-grounded chat response.

    Args:
        query: User's question.
        chunks: Retrieved knowledge chunks from retrieval_service.
        language: ISO language code (en, hi, mr, bn, te, ta, etc.)
        eligibility_context: Optional eligibility result from the rule engine.

    Returns:
        (answer_text, citations, is_grounded)
    """
    lang_name = LANG_NAMES.get(language, "English")

    # Out-of-scope check
    if is_out_of_scope(query):
        fallback = LANG_FALLBACK_MESSAGES.get(
            language,
            "I am Schemora's dedicated Government Scheme Assistant. "
            "I can only answer questions about central/state government schemes, "
            "scholarships, internships, and related educational benefits."
        )
        return fallback, [], False

    # No chunks found
    if not chunks:
        not_found = NOT_FOUND_MESSAGES.get(
            language,
            "I couldn't find verified information for this in the current Schemora "
            "knowledge base. Please check the official government source at https://myscheme.gov.in"
        )
        return not_found, [], False

    citations = _build_citations(chunks)

    # Try Gemini
    api_key = _get_api_key()
    model = _get_generation_model()

    if api_key and len(api_key) > 10:
        prompt = _build_rag_prompt(query, chunks, lang_name, eligibility_context)
        answer = await _call_gemini(prompt, api_key, model)
        if answer:
            return answer, citations, True
        logger.warning("Gemini unavailable — using structured fallback response")

    # Fallback: return structured text from top chunks
    fallback_answer = _build_fallback_response(chunks, language, lang_name)
    return fallback_answer, citations, True
