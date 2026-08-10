import json
import re
from typing import Dict, Any, Tuple
from difflib import SequenceMatcher

NON_LEGAL_DISCLAIMER = (
    "Note: This automated verification is an advisory document analysis tool designed for scheme eligibility guidance "
    "and does not constitute a legally binding document authenticity certificate."
)

DEFAULT_SYNTH_AADHAAR = "9999_8888_1234"
DEFAULT_SYNTH_PAN = "ABCDE-1234-F"


def mask_aadhaar_number(raw: str) -> str:
    digits = re.sub(r"\D", "", raw)
    if len(digits) >= 4:
        return f"XXXX-XXXX-{digits[-4:]}"
    return "XXXX-XXXX-XXXX"


def mask_pan_number(raw: str) -> str:
    cleaned = re.sub(r"[^A-Z0-9]", "", raw.strip().upper())
    if len(cleaned) == 10:
        return f"XXXXX-{cleaned[5:9]}-X"
    return "XXXXX-0000-X"


def parse_document_content(doc_type: str, raw_content: str) -> Dict[str, Any]:
    """Parses raw text/JSON of synthetic document and masks sensitive identifiers."""
    try:
        data = json.loads(raw_content)
    except Exception:
        # Fallback text parsing
        data = {"raw_text": raw_content}

    parsed = {
        "full_name": data.get("full_name") or data.get("name", "Student Name"),
        "date_of_birth": data.get("date_of_birth") or data.get("dob"),
    }

    if doc_type == "Aadhaar":
        raw_id = data.get("aadhaar_number", DEFAULT_SYNTH_AADHAAR)
        parsed["masked_identifier"] = mask_aadhaar_number(raw_id)
        parsed["address"] = data.get("address", "Maharashtra, India")
    elif doc_type == "PAN":
        raw_id = data.get("pan_number", DEFAULT_SYNTH_PAN)
        parsed["masked_identifier"] = mask_pan_number(raw_id)
        parsed["father_name"] = data.get("father_name", "Father Name")
    elif doc_type == "IncomeCertificate":
        parsed["annual_income"] = float(data.get("annual_income", 200000.0))
        parsed["certificate_number"] = data.get("certificate_number", "INC-2026-9876")
        parsed["issuing_authority"] = data.get("issuing_authority", "Tehsildar Office")
        parsed["masked_identifier"] = parsed["certificate_number"]

    return parsed


def compare_document_with_profile(
    doc_type: str,
    extracted_data: Dict[str, Any],
    profile: Any,
) -> Tuple[str, str]:
    """Cross-verifies extracted document data against StudentProfile."""
    issues = []
    warnings = []

    # 1. Name Match Verification
    doc_name = (extracted_data.get("full_name") or "").strip().lower()
    prof_name = (profile.full_name or "").strip().lower()

    if doc_name and prof_name:
        ratio = SequenceMatcher(None, doc_name, prof_name).ratio()
        if ratio < 0.7:
            issues.append(f"Name mismatch: Document has '{extracted_data.get('full_name')}' but profile has '{profile.full_name}'.")
        elif ratio < 0.95:
            warnings.append(f"Minor name spelling difference detected ('{extracted_data.get('full_name')}' vs '{profile.full_name}').")

    # 2. DOB Match Verification (if available)
    doc_dob = str(extracted_data.get("date_of_birth") or "")
    prof_dob = str(profile.date_of_birth or "")
    if doc_dob and prof_dob and doc_dob != prof_dob:
        issues.append(f"Date of Birth mismatch: Document has '{doc_dob}' but profile has '{prof_dob}'.")

    # 3. Income Verification (for Income Certificate)
    if doc_type == "IncomeCertificate":
        doc_income = extracted_data.get("annual_income")
        prof_income = profile.annual_family_income
        if doc_income is not None and prof_income is not None:
            if doc_income > prof_income * 1.5:
                issues.append(f"Income disparity: Certificate states ₹{doc_income:,.2f} which exceeds profile income ₹{prof_income:,.2f}.")
            elif doc_income != prof_income:
                warnings.append(f"Income certificate states ₹{doc_income:,.2f} while profile states ₹{prof_income:,.2f}.")

    # Status classification
    if issues:
        status = "CorrectionRequired"
        notes = " ".join(issues)
    elif warnings:
        status = "Warning"
        notes = " ".join(warnings)
    else:
        status = "Verified"
        notes = "Document details match student profile perfectly."

    return status, notes
