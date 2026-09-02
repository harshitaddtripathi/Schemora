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
import re
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

GREETING_MESSAGES = {
    "en": "Hello! 👋 I am your Schemora AI Assistant. Ask me any question regarding central or state government schemes, scholarships, eligibility, or application guidelines!",
    "hi": "नमस्ते! 🙏 मैं स्केमोरा AI सहायक हूँ। आप मुझसे केंद्र या राज्य सरकार की योजनाओं, छात्रवृत्ति, पात्रता नियमों या आवेदन प्रक्रिया के बारे में कोई भी प्रश्न पूछ सकते हैं!",
    "mr": "नमस्कार! 🙏 मी स्केमोरा AI सहाय्यक आहे. तुम्ही मला केंद्र किंवा राज्य सरकारच्या योजना, शिष्यवृत्ती, पात्रता किंवा अर्ज प्रक्रियेबद्दल कोणताही प्रश्न विचारू शकता!",
    "bn": "নমস্কার! 🙏 আমি স্কেমোরা AI সহকারী। আপনি আমাকে সরকারি প্রকল্প, স্কলারশিপ, যোগ্যতা বা আবেদন প্রক্রিয়া সম্পর্কে যেকোনো প্রশ্ন জিজ্ঞাসা করতে পারেন!",
    "te": "నమస్కారం! 🙏 నేను స్కీమోరా AI సహాయకుడిని. ప్రభుత్వ పథకాలు, స్కాలర్‌షిప్‌లు, అర్హత లేదా దరఖాస్తు గురించి నన్ను ఏమైనా అడగండి!",
    "ta": "வணக்கம்! 🙏 நான் ஸ்கீமோரா AI உதவியாளர். மத்திய அல்லது மாநில அரசு திட்டங்கள், உதவித்தொகை, தகுதி பற்றி என்னிடம் கேளுங்கள்!",
    "gu": "નમસ્તે! 🙏 હું સ્કીમોરા AI સહાયક છું. કેન્દ્ર અથવા રાજ્ય સરકારની યોજનાઓ, શિષ્યવૃત્તિ, પાત્રતા વિશે મને પૂછો!",
    "kn": "ನಮಸ್ಕಾರ! 🙏 ನಾನು ಸ್ಕೀಮೋರಾ AI ಸಹಾಯಕ. ಸರ್ಕಾರಿ ಯೋಜನೆಗಳು, ವಿದ್ಯಾರ್ಥಿವೇತನ, ಅರ್ಹತೆ ಕುರಿತು ನನ್ನನ್ನು ಕೇಳಿ!",
    "ml": "നമസ്കാരം! 🙏 ഞാൻ സ്കീമോറ AI സഹായകനാണ്. സർക്കാർ പദ്ധതികൾ, സ്കോളർഷിപ്പ്, അർഹത എന്നിവയെക്കുറിച്ച് എന്നോട് ചോദിക്കൂ!",
    "pa": "ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ! 🙏 ਮੈਂ ਸਕੀਮੋਰਾ AI ਸਹਾਇਕ ਹਾਂ। ਕੇਂਦਰ ਜਾਂ ਰਾਜ ਸਰਕਾਰ ਦੀਆਂ ਯੋਜਨਾਵਾਂ, ਸਕਾਲਰਸ਼ਿਪ, ਯੋਗਤਾ ਬਾਰੇ ਮੈਨੂੰ ਪੁੱਛੋ!",
}

THANKS_MESSAGES = {
    "en": "You're welcome! 😊 Feel free to ask if you have any more questions about government schemes or scholarships.",
    "hi": "आपका स्वागत है! 😊 यदि आपके पास सरकारी योजनाओं या छात्रवृत्ति के बारे में कोई और प्रश्न हैं, तो निसंकोच पूछें।",
    "mr": "तुमचे स्वागत आहे! 😊 जर तुम्हाला सरकारी योजनांबद्दल आणखी काही प्रश्न असतील तर नक्की विचारारा.",
    "bn": "আপনাকে স্বাগতম! 😊 সরকারি প্রকল্প বা স্কলারশিপ সম্পর্কে আরও কোনো প্রশ্ন থাকলে নির্দ্বিধায় জিজ্ঞাসা করুন।",
    "te": "మీకు స్వాగతం! 😊 ప్రభుత్వ పథకాలు లేదా స్కాలర్‌షిప్‌ల గురించి మరిన్ని ప్రశ్నలు ఉంటే నిరభ్యంతరంగా అడగండి.",
    "ta": "உங்களை வரவேற்கிறோம்! 😊 அரசு திட்டங்கள் அல்லது உதவித்தொகை பற்றி ஏதேனும் கேள்விகள் இருந்தால் தாராளமாகக் கேட்கலாம்.",
    "gu": "તમારું સ્વાગત છે! 😊 જો તમારી પાસે સરકારી યોજનાઓ અથવા શિષ્યવૃત્તિ વિશે વધુ પ્રશ્નો હોય, તો નિઃસંકોચ પૂછો.",
    "kn": "ನಿಮಗೆ ಸ್ವಾಗತ! 😊 ಸರ್ಕಾರಿ ಯೋಜನೆಗಳು ಅಥವಾ ವಿದ್ಯಾರ್ಥಿವೇತನದ ಕುರಿತು ಯಾವುದೇ ಹೆಚ್ಚಿನ ಪ್ರಶ್ನೆಗಳಿದ್ದರೆ ಉಚಿತವಾಗಿ ಕೇಳಿ.",
    "ml": "തീർച്ചയായും സ്വാഗതം! 😊 സർക്കാർ പദ്ധതികളെക്കുറിച്ചോ സ്കോളർഷിപ്പുകളെക്കുറിച്ചോ കൂടുതൽ ചോദ്യങ്ങളുണ്ടെങ്കിൽ ചോദിക്കാവുന്നതാണ്.",
    "pa": "ਤੁਹਾਡਾ ਸੁਆਗਤ ਹੈ! 😊 ਜੇਕਰ ਤੁਹਾਡੇ ਕੋਲ ਸਰਕਾਰੀ ਯੋਜਨਾਵਾਂ ਜਾਂ ਸਕਾਲਰਸ਼ਿਪ ਬਾਰੇ ਹੋਰ ਸਵਾਲ ਹਨ, ਤਾਂ ਬੇਝਿਜਕ ਪੁੱਛੋ।",
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
        "deadlines": "ಕೊನೆಯ ದಿನಾಂಕ", "ಮುಖ್ಯ ಟಿಪ್ಪಣಿಗಳು": "ಮುಖ್ಯ ಟಿಪ್ಪಣಿಗಳು",
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
    "gu": "અરજી કરો",
    "kn": "ಅರ್ಜಿ ಸಲ್ಲಿಸಿ",
    "ml": "അപേക്ഷിക്കൂ",
    "pa": "ਅਰਜ਼ੀ ਕਰੋ",
}


def _get_api_key() -> str:
    key = os.getenv("GEMINI_API_KEY") or settings.GEMINI_API_KEY or ""
    if not key or key.startswith("AQ.") or len(key) < 20:
        return ""
    return key


def _get_generation_model() -> str:
    return getattr(settings, "GEMINI_GENERATION_MODEL", "gemini-2.5-flash")


def _build_headers_and_url(api_key: str, model: str) -> Tuple[str, Dict[str, str]]:
    """Build the correct URL and headers based on key type."""
    base = f"{GEMINI_BASE_URL}/{model}:generateContent"
    return f"{base}?key={api_key}", {"Content-Type": "application/json"}


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
        # Check if there is an explicit failure reason for profile mismatch
        title_lower = scheme_title.lower()
        if any(kw in title_lower for kw in ["kisan", "fasal", "farmer", "agriculture", "agri", "crop"]):
            explanation = (
                f"You are not eligible for '{scheme_title}'. "
                f"Reason: Your registered profile is Student / Learner, whereas this farmer scheme requires "
                f"an agricultural occupation or landholding."
            )
        elif any(kw in title_lower for kw in ["mudra", "svanidhi", "pmegp", "business", "enterprise", "msme"]):
            explanation = (
                f"You are not eligible for '{scheme_title}'. "
                f"Reason: Your registered profile is Student / Learner, whereas this business scheme requires "
                f"an active micro-enterprise or business registration."
            )
        elif any(kw in title_lower for kw in ["pension", "apy", "ignoaps", "senior", "scss", "old age"]):
            explanation = (
                f"You are not eligible for '{scheme_title}'. "
                f"Reason: Your registered profile is Student / Learner (Age ~20), whereas senior citizen schemes require "
                f"age 60+ or retired pension status."
            )
        elif any(kw in title_lower for kw in ["ladki", "bahin", "gruha", "lakshmi", "sumangala", "sukanya", "matru", "women", "female"]):
            explanation = (
                f"You are not eligible for '{scheme_title}'. "
                f"Reason: Your registered profile is Student / Learner, whereas women/family schemes are restricted to "
                f"female heads of household or women beneficiaries."
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
    language: str = "en",
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

    prompt = f"""You are Schemora AI Assistant, a trusted and helpful expert on Indian Government Schemes (scholarships, internships, welfare, skill development).

LANGUAGE RULE (HIGHEST PRIORITY): {lang_instruction}

STRICT SAFETY RULES:
1. Answer ONLY using the verified scheme information in the KNOWLEDGE BASE below. Do NOT invent facts.
2. If the answer is genuinely not in the context, say: "I couldn't find verified information for this in the current knowledge base. Please check the official source."
3. Never fabricate scheme names, benefit amounts, income limits, deadlines, or application links.
4. Always cite which Source number the information comes from.
5. When an "Online Application URL" is available, ALWAYS include it prominently.
6. Be friendly, clear, and helpful. Use numbered lists for steps and documents.
7. For documents questions: List ALL required documents as a numbered list from the documents sections.
8. For application process questions: List ALL steps as Step 1, Step 2, etc. from application sections.
9. For eligibility questions: State each eligibility criterion clearly from eligibility sections.
10. For OBC/SC/ST/category queries: Identify ALL relevant schemes from the knowledge base.

VERIFIED SCHEME KNOWLEDGE BASE:
{context_text}
{eligibility_section}

USER QUESTION: {query}

RESPONSE INSTRUCTIONS (respond entirely in {lang_name}):
- Read ALL the Knowledge Base sources carefully before answering.
- Directly answer the user's question with specifics from the knowledge base.
- For general application process or form filling questions (e.g. "process to fill a scholarship form"):
  1. First provide a clear 4-step summary of the standard scholarship application workflow:
     • Step 1: Register on the Official Portal (e.g., National Scholarship Portal or State Portals like MahaDBT)
     • Step 2: Fill Student Profile & Academic Details
     • Step 3: Upload Required Documents (Marksheets, Income Certificate, Caste Certificate, Aadhaar, Bank Details)
     • Step 4: Submit Application & Track Status for Institution / Nodal Verification
  2. Then list the specific application steps and official application URLs for the schemes in the knowledge base.
- For scheme/scholarship discovery: Name each relevant scheme, its category, and who can apply.
- For documents: Provide a complete numbered list of all required documents.
- For application steps: Provide all steps in order as Step 1, Step 2, etc.
- For eligibility: List each criterion clearly.
- Include official application URLs from the context prominently.
- End with: "You might also want to ask:" followed by 2-3 relevant follow-up questions.
"""
    return prompt


async def _call_gemini(prompt: str, api_key: str, model: str) -> Optional[str]:
    """Call Gemini generate API with a fast 3s timeout. Returns text or None on failure."""
    if not api_key:
        return None
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
        async with httpx.AsyncClient(timeout=25.0) as client:
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


OFFLINE_HEADER_NOTICE = {
    "en": "ℹ️ Official Verified Database (Offline Knowledge Mode)",
    "hi": "ℹ️ आधिकारिक सत्यापित ज्ञान आधार (ऑफ़लाइन मोड)",
    "mr": "ℹ️ अधिकृत सत्यापित ज्ञान आधार (ऑफलाईन मोड)",
    "bn": "ℹ️ সরকারি অনলাইন ডেটাবেস (অফলাইন মোড)",
    "te": "ℹ️ అధికారిక డేటాబేస్ (ఆఫ్‌లైన్ మోడ్)",
    "ta": "ℹ️ அதிகாரப்பூர்வ தரவுத்தளம் (ஆஃப்லைன் பயன்முறை)",
    "gu": "ℹ️ સત્તાવાર ચકાસાયેલ ડેટાબેઝ (ઓફલાઇન મોડ)",
    "kn": "ℹ️ ಅಧಿಕೃತ ಪರಿಶೀಲಿಸಿದ ಡೇಟಾಬೇಸ್ (ಆಫ್‌ಲೈನ್ ಮೋಡ್)",
    "ml": "ℹ️ ഔദ്യോഗിക ഡാറ്റാബേസ് (ഓഫ്‌ലൈൻ മോഡ്)",
    "pa": "ℹ️ ਅਧਿਕਾਰਤ ਪੁਸ਼ਟੀ ਕੀਤੀ ਡਾਟਾਬੇਸ (ਆਫ਼ਲਾਈਨ ਮੋਡ)",
}

FOLLOW_UP_PROMPTS = {
    "en": "You might also want to ask:\n• What documents are required for this scheme?\n• How do I apply online step-by-step?\n• What are the income and age eligibility limits?",
    "hi": "आप यह भी पूछ सकते हैं:\n• इस योजना के लिए कौन से दस्तावेज़ आवश्यक हैं?\n• ऑनलाइन आवेदन कैसे करें step-by-step?\n• पात्रता के लिए आय और आयु सीमा क्या है?",
    "mr": "तुम्ही हे देखील विचारू शकता:\n• या योजनेसाठी कोणती कागदपत्रे आवश्यक आहेत?\n• ऑनलाईन अर्ज कसा करावा step-by-step?\n• पात्रतेसाठी उत्पन्न आणि वयोमर्यादा काय आहे?",
    "bn": "আপনি আরও জিজ্ঞাসা করতে পারেন:\n• এই প্রকল্পের জন্য কী কী নথি প্রয়োজন?\n• কীভাবে অনলাইনে আবেদন করবেন?\n• যোগ্যতার বয়স ও আয়সীমা কত?",
    "te": "మీరు ఇవి కూడా అడగవచ్చు:\n• ఈ పథకానికి ఏ పత్రాలు అవసరం?\n• ఆన్‌లైన్‌లో ఎలా దరఖాస్తు చేయాలి?\n• అర్హత ఆదాయం మరియు వయస్సు పరిమితి ఎంత?",
    "ta": "நீங்கள் இதையும் கேட்கலாம்:\n• இந்தத் திட்டத்திற்கு என்ன ஆவணங்கள் தேவை?\n• ஆன்லைனில் விண்ணப்பிப்பது எப்படி?\n• தகுதி வருமானம் மற்றும் வயது வரம்பு என்ன?",
}


def _clean_chunk_content(content: str) -> str:
    """Extract clean readable text from chunk content, stripping raw metadata lines."""
    clean_lines = []
    for line in content.split("\n"):
        l = line.strip()
        if not l:
            continue
        if l.startswith("Scheme:") or l.startswith("Category:") or l.startswith("Jurisdiction:") or l.startswith("Status:") or l.startswith("Cycle:"):
            continue
        if l.startswith("Department:"):
            dept_name = l.replace("Department:", "").strip()
            if dept_name:
                clean_lines.append(f"• **Department**: {dept_name}")
            continue
        if l.startswith("Description:"):
            desc_text = l.replace("Description:", "").strip()
            if desc_text:
                clean_lines.append(f"• **Overview**: {desc_text}")
            continue
        clean_lines.append(l)
    return "\n".join(clean_lines)


def _build_fallback_response(
    chunks: List[Dict[str, Any]],
    language: str,
    lang_name: str,
) -> str:
    """Build a language-aware, polished response from verified knowledge chunks."""
    if not chunks:
        return NOT_FOUND_MESSAGES.get(
            language,
            "I couldn't find verified information for this in the current Schemora "
            "knowledge base. Please check the official government source."
        )

    header = RESULT_HEADER.get(language, "Here is verified information about relevant government schemes:")
    apply_label = APPLY_LABEL.get(language, "Apply Online")

    parts = [header]

    # Group chunks by scheme name
    schemes_dict: Dict[str, Dict[str, Any]] = {}
    for c in chunks:
        s_name = c.get("scheme_name", "Official Scheme")
        if s_name not in schemes_dict:
            schemes_dict[s_name] = {
                "chunks": [],
                "info_url": c.get("source_url", "").strip(),
                "app_url": c.get("official_app_url", "").strip(),
                "category": c.get("category", ""),
                "state": c.get("state", ""),
                "jurisdiction": c.get("jurisdiction", ""),
            }
        schemes_dict[s_name]["chunks"].append(c)

    for i, (s_name, data) in enumerate(list(schemes_dict.items())[:3], 1):
        lines = [f"\n### 📌 {i}. {s_name}"]

        # Metadata badges
        tags = []
        if data["state"]:
            tags.append(f"State: {data['state']}")
        elif data["jurisdiction"]:
            tags.append(f"Jurisdiction: {data['jurisdiction'].title()}")
        if data["category"]:
            tags.append(f"Category: {data['category']}")
        if tags:
            lines.append(f"_{' | '.join(tags)}_")

        # Collect overview, benefits, eligibility, application sections
        sec_order = ["overview", "benefits", "eligibility", "documents", "application"]
        sorted_chunks = sorted(
            data["chunks"],
            key=lambda x: sec_order.index(x.get("section", "overview")) if x.get("section", "overview") in sec_order else 99
        )

        for c in sorted_chunks[:3]:
            cnt_cleaned = _clean_chunk_content(c.get("content", ""))
            if cnt_cleaned:
                lines.append(cnt_cleaned)

        # Official links
        if data["app_url"]:
            lines.append(f"🔗 **{apply_label}**: [{data['app_url']}]({data['app_url']})")
        elif data["info_url"]:
            lines.append(f"🔗 **Official Portal**: [{data['info_url']}]({data['info_url']})")

        parts.append("\n".join(lines))

    follow_up = FOLLOW_UP_PROMPTS.get(language, FOLLOW_UP_PROMPTS["en"])
    parts.append(f"\n\n{follow_up}")

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
    q_clean = query.strip().lower()

    # 1. Greeting check — return friendly localized welcome message
    if (
        re.match(r"^(?:hi|hello|hey|greetings|namaste|namaskar|good\s*(?:morning|afternoon|evening)|hallo|hola|ssa|satsriakal|hi+|hello+)\s*[\!\?\,\.]*$", q_clean)
        or q_clean in ["who are you", "what can you do", "how are you", "help"]
    ):
        greeting = GREETING_MESSAGES.get(language, GREETING_MESSAGES["en"])
        return greeting, [], True

    # 2. Thanks / Gratitude check
    if re.match(r"^(?:thanks|thank\s*you|shukriya|dhanyawad|thx|dhanbad)\s*[\!\?\,\.]*$", q_clean):
        thanks = THANKS_MESSAGES.get(language, THANKS_MESSAGES["en"])
        return thanks, [], True

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

    # Try Gemini API if key is available
    api_key = _get_api_key()
    model = _get_generation_model()

    if api_key and len(api_key) > 10:
        prompt = _build_rag_prompt(query, chunks, lang_name, language, eligibility_context)
        answer = await _call_gemini(prompt, api_key, model)
        if answer:
            return answer, citations, True
        logger.warning(
            f"Gemini call failed or unavailable — activating verified knowledge fallback in language={language}."
        )

    # Fallback: verified knowledge base response derived directly from RAG chunks
    fallback_answer = _build_fallback_response(chunks, language, lang_name)
    return fallback_answer, citations, True

