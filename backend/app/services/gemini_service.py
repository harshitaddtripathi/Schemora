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
    "en": "English",
    "hi": "Hindi", "mr": "Marathi", "bn": "Bengali", "te": "Telugu",
    "ta": "Tamil", "gu": "Gujarati", "kn": "Kannada", "ml": "Malayalam",
    "pa": "Punjabi", "or": "Odia", "as": "Assamese", "ur": "Urdu",
    "sa": "Sanskrit", "ne": "Nepali", "sd": "Sindhi", "kok": "Konkani",
    "mai": "Maithili", "doi": "Dogri", "bho": "Bhojpuri",
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
    "bn": "এই প্রশ্নের জন্য যথেষ্ট তথ্য পাওয়া যায়নি। অনুগ্রহ করে সরকারি পোর্টাল দেখুন।",
    "te": "ఈ ప్రశ్నకు సంబంధించిన సమాచారం కనుగొనబడలేదు. దయచేసి అధికారిక ప్రభుత్వ పోర్టల్ చూడండి.",
    "ta": "இந்தக் கேள்விக்கு போதுமான தகவல் கிடைக்கவில்லை. அரசு இணையதளத்தைப் பார்க்கவும்.",
    "gu": "આ પ્રશ્ન માટે પૂરતી માહિતી મળી નથી. કૃપા કરી સત્તાવાર સরકારી પોર્ટલ જુઓ.",
    "kn": "ಈ ಪ್ರಶ್ನೆಗೆ ಸಂಬಂಧಿಸಿದ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ. ದಯವಿಟ್ಟು ಅಧಿಕೃತ ಸರ್ಕಾರಿ ಪೋರ್ಟಲ್ ನೋಡಿ.",
    "ml": "ഈ ചോദ്യത്തിന് ആവശ്യമായ വിവരങ്ങൾ കണ്ടെത്തിയില്ല. ഔദ്യോഗിക സർക്കാർ പോർട്ടൽ പരിശോധിക്കൂ.",
    "pa": "ਇਸ ਸਵਾਲ ਲਈ ਕਾਫ਼ੀ ਜਾਣਕਾਰੀ ਨਹੀਂ ਮਿਲੀ। ਕਿਰਪਾ ਕਰਕੇ ਸਰਕਾਰੀ ਪੋਰਟਲ ਵੇਖੋ।",
}

# Language-specific labels for the fallback response header
RESULT_HEADER = {
    "hi": "यहाँ आपके प्रश्न से संबंधित सरकारी योजनाओं की जानकारी है:",
    "mr": "तुमच्या प्रश्नाशी संबंधित सरकारी योजनांची माहिती येथे आहे:",
    "bn": "আপনার প্রশ্নের সাথে সম্পর্কিত সরকারি প্রকল্পের তথ্য:",
    "te": "మీ ప్రశ్నకు సంబంధించిన ప్రభుత్వ పథకాల సమాచారం:",
    "ta": "உங்கள் கேள்விக்கு தொடர்புடைய அரசு திட்டங்கள்:",
    "gu": "તમારા પ્રશ્ન સંબંધિત સરકારી યોજનાઓની માહિતી:",
    "kn": "ನಿಮ್ಮ ಪ್ರಶ್ನೆಗೆ ಸಂಬಂಧಿಸಿದ ಸರ್ಕಾರಿ ಯೋಜನೆಗಳ ಮಾಹಿತಿ:",
    "ml": "നിങ്ങളുടെ ചോദ്യവുമായി ബന്ധപ്പെട്ട സർക്കാർ പദ്ധതികൾ:",
    "pa": "ਤੁਹਾਡੇ ਸਵਾਲ ਨਾਲ ਸੰਬੰਧਿਤ ਸਰਕਾਰੀ ਯੋਜਨਾਵਾਂ:",
    "ur": "آپ کے سوال سے متعلق سرکاری اسکیمیں:",
    "or": "ଆପଣଙ୍କ ପ୍ରଶ୍ନ ସଂକ୍ରାନ୍ତ ସରକାରୀ ଯୋଜନାଗୁଡ଼ିକ:",
}

SECTION_LABELS = {
    "hi": {
        "overview": "अवलोकन", "benefits": "लाभ", "eligibility": "पात्रता",
        "documents": "दस्तावेज़", "application": "आवेदन प्रक्रिया",
        "deadlines": "अंतिम तिथि", "notes": "महत्वपूर्ण नोट",
    },
    "mr": {
        "overview": "आढावा", "benefits": "फायदे", "eligibility": "पात्रता",
        "documents": "कागदपत्रे", "application": "अर्ज प्रक्रिया",
        "deadlines": "अंतिम मुदत", "notes": "महत्त्वाच्या नोंदी",
    },
    "bn": {
        "overview": "সারসংক্ষেপ", "benefits": "সুবিধা", "eligibility": "যোগ্যতা",
        "documents": "নথিপত্র", "application": "আবেদন প্রক্রিয়া",
        "deadlines": "শেষ তারিখ", "notes": "গুরুত্বপূর্ণ তথ্য",
    },
    "te": {
        "overview": "అవలోకనం", "benefits": "ప్రయోజనాలు", "eligibility": "అర్హత",
        "documents": "పత్రాలు", "application": "దరఖాస్తు ప్రక్రియ",
        "deadlines": "చివరి తేదీ", "notes": "ముఖ్యమైన గమనికలు",
    },
    "ta": {
        "overview": "மேலோட்டம்", "benefits": "நன்மைகள்", "eligibility": "தகுதி",
        "documents": "ஆவணங்கள்", "application": "விண்ணப்ப செயல்முறை",
        "deadlines": "இறுதி தேதி", "notes": "முக்கிய குறிப்புகள்",
    },
    "gu": {
        "overview": "ઝાંખી", "benefits": "ફાયદા", "eligibility": "પાત્રતા",
        "documents": "દસ્તાવેજો", "application": "અરજી પ્રક્રિયા",
        "deadlines": "છેલ્લી તારીખ", "notes": "મહત્ત્વની નોંધ",
    },
    "kn": {
        "overview": "ಅವಲೋಕನ", "benefits": "ಪ್ರಯೋಜನಗಳು", "eligibility": "ಅರ್ಹತೆ",
        "documents": "ದಾಖಲೆಗಳು", "application": "ಅರ್ಜಿ ಪ್ರಕ್ರಿಯೆ",
        "deadlines": "ಕೊನೆಯ ದಿನಾಂಕ", "notes": "ಮುಖ್ಯ ಟಿಪ್ಪಣಿಗಳು",
    },
    "ml": {
        "overview": "അവലോകനം", "benefits": "ആനുകൂല്യങ്ങൾ", "eligibility": "അർഹത",
        "documents": "രേഖകൾ", "application": "അപേക്ഷ പ്രക്രിയ",
        "deadlines": "അവസാന തീയതി", "notes": "പ്രധാന കുറിപ്പുകൾ",
    },
    "pa": {
        "overview": "ਜਾਣ-ਪਛਾਣ", "benefits": "ਲਾਭ", "eligibility": "ਯੋਗਤਾ",
        "documents": "ਦਸਤਾਵੇਜ਼", "application": "ਅਰਜ਼ੀ ਪ੍ਰਕਿਰਿਆ",
        "deadlines": "ਆਖਰੀ ਤਾਰੀਖ਼", "notes": "ਮਹੱਤਵਪੂਰਨ ਨੋਟ",
    },
}

APPLY_LABEL = {
    "hi": "ਆਵੇਦਨ ਕਰੋ",
    "mr": "अर्ज करा",
    "bn": "আবেদন করুন",
    "te": "దరఖాస్తు చేయండి",
    "ta": "விண்ணப்பிக்கவும்",
    "gu": "અরજી કરો",
    "kn": "ಅರ್ಜಿ ಸಲ್ಲಿಸಿ",
    "ml": "അപേക്ഷിക്കൂ",
    "pa": "ਅਰਜ਼ੀ ਕਰੋ",
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
    citations = []
    for s in sources:
        url = s.get("url", "").strip()
        if url:
            citations.append({
                "source_name": s.get("source_name", "Official Portal"),
                "url": url,
                "last_verified_at": s.get("last_verified_at", "2026-08-07"),
            })

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
    language: str,
    eligibility_context: Optional[str] = None,
) -> str:
    """Build a safety-first grounded prompt for Gemini."""

    # Build context block from chunks — include real official URLs so Gemini cites them
    context_lines = []
    for i, c in enumerate(chunks, 1):
        scheme_name = c.get("scheme_name", "")
        section = c.get("section", "")
        content = c.get("content", "")
        verified = c.get("last_verified_at", "")
        info_url = c.get("source_url", "").strip()
        app_url = c.get("official_app_url", "").strip()
        url_line = ""
        if info_url:
            url_line += f"\nOfficial Info URL: {info_url}"
        if app_url:
            url_line += f"\nOnline Application URL: {app_url}"
        context_lines.append(
            f"[Source {i}] {scheme_name} ({section.title()}) — Verified: {verified}{url_line}\n{content}"
        )
    context_text = "\n\n".join(context_lines)

    eligibility_section = ""
    if eligibility_context:
        eligibility_section = f"""
ELIGIBILITY RESULT (from deterministic rule engine — do NOT override):
{eligibility_context}
"""

    # Strong language enforcement — triple stated
    lang_instruction = (
        f"CRITICAL: You MUST respond entirely in {lang_name}. "
        f"Every word of your answer must be in {lang_name}. "
        f"Do not switch to English. "
        f"Keep scheme names, URLs, and numbers in their original form, but all explanatory text must be in {lang_name}."
        if language != "en"
        else "Respond in English."
    )

    prompt = f"""You are Schemora AI Assistant, a trusted expert on Indian Government Schemes (scholarships, internships, welfare, agriculture, skill development).

LANGUAGE RULE (HIGHEST PRIORITY): {lang_instruction}

STRICT SAFETY RULES — follow without exception:
1. Answer ONLY using the verified scheme information provided below. Do NOT invent facts.
2. If the answer is not found in the context, say so in {lang_name}: "I couldn't find verified information for this."
3. Never fabricate: scheme names, benefit amounts, income limits, deadlines, or application links.
4. Always indicate which source each piece of information comes from.
5. Clearly distinguish: Verified information vs. information requiring verification.
6. If a field says "requires verification", say so honestly in {lang_name}.
7. Keep scheme names and official URLs in their original form, but explain everything else in {lang_name}.
8. Be friendly, clear, and helpful. Use simple language. Guide the user step by step.
9. When an "Online Application URL" is in the context, ALWAYS share it.
10. Give a SPECIFIC, DETAILED answer — NOT a generic overview.

VERIFIED SCHEME KNOWLEDGE BASE:
{context_text}
{eligibility_section}

USER QUESTION: {query}

RESPONSE FORMAT (all in {lang_name}):
- Specific, detailed answer based on the retrieved scheme information
- Name the specific scheme(s) that answer this question
- Quote exact benefit amounts, eligibility criteria, deadlines from context
- If an Online Application URL is available, share it clearly
- If any info requires verification, say so and give the official info URL
- End with 2-3 follow-up questions in {lang_name}
- Format follow-ups as: "You might also want to ask: ..."
"""
    return prompt


async def _call_gemini(prompt: str, api_key: str, model: str) -> Optional[str]:
    """Call Gemini generate API. Returns text or None on failure."""
    url, headers = _build_headers_and_url(api_key, model)
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 2000,
            "topP": 0.8,
        },
    }
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(url, json=payload, headers=headers)
        if resp.status_code == 200:
            data = resp.json()
            return data["candidates"][0]["content"]["parts"][0]["text"].strip()
        else:
            logger.warning(
                f"Gemini generate API error {resp.status_code}: {resp.text[:300]}\n"
                f"Hint: Your GEMINI_API_KEY may be invalid. Get a valid key from "
                f"https://aistudio.google.com/app/apikey (must start with 'AIzaSy')"
            )
            return None
    except Exception as e:
        logger.error(f"Gemini generate call failed: {e}")
        return None


def _build_citations(chunks: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Build deduplicated citation list — only real government URLs."""
    seen_urls = set()
    citations = []
    for c in chunks:
        info_url = c.get("source_url", "").strip()
        if info_url and info_url not in seen_urls:
            seen_urls.add(info_url)
            citations.append({
                "source_name": c.get("source_title", "Official Government Source"),
                "url": info_url,
                "last_verified_at": c.get("last_verified_at", "2026-08-07"),
            })
        app_url = c.get("official_app_url", "").strip()
        if app_url and app_url not in seen_urls:
            seen_urls.add(app_url)
            scheme_name = c.get("scheme_name", "Official")
            citations.append({
                "source_name": f"{scheme_name} — Apply Online",
                "url": app_url,
                "last_verified_at": c.get("last_verified_at", "2026-08-07"),
            })
    return citations


def _build_fallback_response(
    chunks: List[Dict[str, Any]],
    language: str,
    lang_name: str,
) -> str:
    """
    Build a language-aware fallback when Gemini is unavailable.
    Uses localized section labels and headers so the response feels native.
    """
    if not chunks:
        return NOT_FOUND_MESSAGES.get(
            language,
            "I couldn't find verified information for this in the current Schemora "
            "knowledge base. Please check the official government source."
        )

    header = RESULT_HEADER.get(language, "Here is information about relevant government schemes:")
    section_labels = SECTION_LABELS.get(language, {})
    apply_label = APPLY_LABEL.get(language, "Apply Online")

    parts = [header]
    seen_schemes: set = set()

    for c in chunks[:4]:
        name = c.get("scheme_name", "")
        section = c.get("section", "")
        content = c.get("content", "")
        app_url = c.get("official_app_url", "").strip()
        info_url = c.get("source_url", "").strip()

        # Avoid duplicating the same scheme multiple times in fallback
        if name in seen_schemes:
            continue
        seen_schemes.add(name)

        # Localize the section label
        section_label = section_labels.get(section, section.title())

        url_part = ""
        if app_url:
            url_part = f"\n  {apply_label}: {app_url}"
        elif info_url:
            url_part = f"\n  Info: {info_url}"

        parts.append(f"\n{name} ({section_label}):\n{content[:700]}{url_part}")

    return "\n".join(parts)


async def generate_grounded_chat_response(
    query: str,
    chunks: List[Dict[str, Any]],
    language: str = "en",
    eligibility_context: Optional[str] = None,
) -> Tuple[str, List[Dict[str, Any]], bool]:
    """Generate a RAG-grounded chat response in the requested language.

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
            "knowledge base. Please check the official government source."
        )
        return not_found, [], False

    citations = _build_citations(chunks)

    # Try Gemini with whatever key is configured — let the API reject it if invalid
    api_key = _get_api_key()
    model = _get_generation_model()

    if api_key and len(api_key) > 10:
        prompt = _build_rag_prompt(query, chunks, lang_name, language, eligibility_context)
        answer = await _call_gemini(prompt, api_key, model)
        if answer:
            return answer, citations, True
        logger.warning(
            f"Gemini call failed — falling back to structured response in language={language}. "
            "Ensure GEMINI_API_KEY is valid (must start with 'AIzaSy'). "
            "Get one at: https://aistudio.google.com/app/apikey"
        )

    # Fallback: language-aware structured response from top chunks
    fallback_answer = _build_fallback_response(chunks, language, lang_name)
    return fallback_answer, citations, False
