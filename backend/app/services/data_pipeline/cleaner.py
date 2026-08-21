import re
import json
import hashlib
from typing import Dict, Any, List, Optional, Tuple

# Mapping of state codes/variations to standard State/UT names
STATE_NAME_MAPPING = {
    "mh": "Maharashtra",
    "maharashtra": "Maharashtra",
    "up": "Uttar Pradesh",
    "uttar pradesh": "Uttar Pradesh",
    "gj": "Gujarat",
    "gujarat": "Gujarat",
    "ka": "Karnataka",
    "karnataka": "Karnataka",
    "tn": "Tamil Nadu",
    "tamil nadu": "Tamil Nadu",
    "wb": "West Bengal",
    "west bengal": "West Bengal",
    "dl": "Delhi",
    "delhi": "Delhi",
    "delhi (nct)": "Delhi",
    "nct of delhi": "Delhi",
    "br": "Bihar",
    "bihar": "Bihar",
    "rj": "Rajasthan",
    "rajasthan": "Rajasthan",
    "mp": "Madhya Pradesh",
    "madhya pradesh": "Madhya Pradesh",
    "kl": "Kerala",
    "kerala": "Kerala",
    "pb": "Punjab",
    "punjab": "Punjab",
    "hr": "Haryana",
    "haryana": "Haryana",
    "ap": "Andhra Pradesh",
    "andhra pradesh": "Andhra Pradesh",
    "ts": "Telangana",
    "telangana": "Telangana",
    "od": "Odisha",
    "orissa": "Odisha",
    "odisha": "Odisha",
    "as": "Assam",
    "assam": "Assam",
    "jh": "Jharkhand",
    "jharkhand": "Jharkhand",
    "uk": "Uttarakhand",
    "uttarakhand": "Uttarakhand",
    "hp": "Himachal Pradesh",
    "himachal pradesh": "Himachal Pradesh",
    "cg": "Chhattisgarh",
    "chhattisgarh": "Chhattisgarh",
    "ga": "Goa",
    "goa": "Goa",
    "jk": "Jammu and Kashmir",
    "jammu & kashmir": "Jammu and Kashmir",
    "jammu and kashmir": "Jammu and Kashmir",
}

CATEGORY_MAPPING = {
    "agri": "Agriculture",
    "agriculture": "Agriculture",
    "farmer": "Agriculture",
    "education": "Education",
    "student": "Education",
    "scholarship": "Education",
    "skill": "Skill & Employment",
    "job seeker": "Skill & Employment",
    "employment": "Skill & Employment",
    "business": "Business & MSME",
    "msme": "Business & MSME",
    "entrepreneurship": "Business & MSME",
    "women": "Women & Child Development",
    "female": "Women & Child Development",
    "senior": "Senior Citizen & Pension",
    "pension": "Senior Citizen & Pension",
    "elderly": "Senior Citizen & Pension",
    "health": "Health & Healthcare",
    "medical": "Health & Healthcare",
    "housing": "Housing & Social Welfare",
    "welfare": "Housing & Social Welfare",
    "social": "Housing & Social Welfare",
}


def normalize_string(text: Optional[str]) -> str:
    if not text:
        return ""
    return re.sub(r"\s+", " ", str(text)).strip()


def normalize_slug(title: str) -> str:
    clean = re.sub(r"[^\w\s-]", "", title.lower())
    return re.sub(r"[-\s]+", "-", clean).strip("-")


def normalize_state(state_input: Optional[str]) -> Optional[str]:
    if not state_input:
        return None
    cleaned = state_input.strip().lower()
    return STATE_NAME_MAPPING.get(cleaned, state_input.strip().title())


def normalize_government_level(level_raw: Optional[str], state: Optional[str]) -> str:
    if state and state.strip():
        return "state"
    if not level_raw:
        return "central"
    cleaned = level_raw.strip().lower()
    if "state" in cleaned:
        return "state"
    return "central"


def normalize_gender(gender_raw: Any) -> List[str]:
    if not gender_raw:
        return ["all"]

    if isinstance(gender_raw, list):
        items = [str(g).lower() for g in gender_raw]
    else:
        items = [g.strip().lower() for g in str(gender_raw).split(",")]

    results = set()
    for g in items:
        if "all" in g or "any" in g or "both" in g:
            results.add("all")
        elif "female" in g or "women" in g or "woman" in g:
            results.add("female")
        elif "male" in g or "men" in g or "man" in g:
            results.add("male")
        elif "trans" in g:
            results.add("transgender")

    return list(results) if results else ["all"]


def normalize_social_category(cat_raw: Any) -> List[str]:
    if not cat_raw:
        return []

    if isinstance(cat_raw, list):
        items = [str(c).upper() for c in cat_raw]
    else:
        items = [c.strip().upper() for c in str(cat_raw).replace(";", ",").split(",")]

    valid_categories = {"SC", "ST", "OBC", "GENERAL", "EWS", "MINORITY"}
    results = set()
    for item in items:
        if "ALL" in item or "ANY" in item:
            return ["SC", "ST", "OBC", "General", "EWS"]
        for valid in valid_categories:
            if valid in item:
                results.add("General" if valid == "GENERAL" else valid)

    return list(results)


def parse_income_amount(val_raw: Any) -> Optional[float]:
    """Parses various income formats e.g. ₹2 Lakh, 2,00,000, 200000, Rs 2.5 L."""
    if val_raw is None:
        return None

    if isinstance(val_raw, (int, float)):
        return float(val_raw)

    text = str(val_raw).lower().replace(",", "").replace("₹", "").replace("rs", "").replace("inr", "").strip()
    if not text or text == "null" or text == "none":
        return None

    try:
        # Check for Lakh / L
        lakh_match = re.search(r"([\d.]+)\s*(lakh|lakhs|l)\b", text)
        if lakh_match:
            amount = float(lakh_match.group(1)) * 100000
            return amount

        # Check for Crore / Cr
        crore_match = re.search(r"([\d.]+)\s*(crore|crores|cr)\b", text)
        if crore_match:
            amount = float(crore_match.group(1)) * 10000000
            return amount

        # Extract pure number
        num_match = re.search(r"([\d.]+)", text)
        if num_match:
            return float(num_match.group(1))
    except Exception:
        pass

    return None


def parse_age_range(val_raw: Any) -> Tuple[Optional[float], Optional[float]]:
    """Extracts min and max age from strings or dicts e.g. '18 to 60 years'."""
    if val_raw is None:
        return (None, None)

    if isinstance(val_raw, dict):
        return (
            float(val_raw["min"]) if val_raw.get("min") is not None else None,
            float(val_raw["max"]) if val_raw.get("max") is not None else None,
        )

    text = str(val_raw).lower()
    min_age = None
    max_age = None

    range_match = re.search(r"(\d+)\s*(?:to|-|until)\s*(\d+)", text)
    if range_match:
        min_age = float(range_match.group(1))
        max_age = float(range_match.group(2))
        return (min_age, max_age)

    above_match = re.search(r"(?:above|min|minimum|greater than|>=|\+)\s*(\d+)", text)
    if above_match:
        min_age = float(above_match.group(1))

    below_match = re.search(r"(?:below|max|maximum|up to|less than|<=)\s*(\d+)", text)
    if below_match:
        max_age = float(below_match.group(1))

    return (min_age, max_age)


def normalize_url(url_raw: Optional[str]) -> str:
    if not url_raw:
        return ""
    cleaned = str(url_raw).strip()
    if cleaned.startswith("http://") or cleaned.startswith("https://"):
        return cleaned
    if cleaned.startswith("www."):
        return f"https://{cleaned}"
    return ""


def calculate_content_hash(scheme_dict: Dict[str, Any]) -> str:
    """Calculates SHA-256 hash of normalized scheme representation."""
    serialized = json.dumps(scheme_dict, sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()
