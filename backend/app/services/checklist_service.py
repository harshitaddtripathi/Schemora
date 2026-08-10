from typing import List, Dict, Any


REQUIRED_DOC_MAPPING = {
    "sch-central-csss-001": [
        {"doc_type": "Aadhaar", "title": "Aadhaar Card (Identity & Age)", "is_mandatory": True},
        {"doc_type": "IncomeCertificate", "title": "Family Income Certificate", "is_mandatory": True},
    ],
    "sch-maharashtra-obc-postmatric-002": [
        {"doc_type": "Aadhaar", "title": "Aadhaar Card", "is_mandatory": True},
        {"doc_type": "IncomeCertificate", "title": "OBC Income & Caste Certificate", "is_mandatory": True},
    ],
    "sch-central-pmis-003": [
        {"doc_type": "Aadhaar", "title": "Aadhaar Card", "is_mandatory": True},
        {"doc_type": "PAN", "title": "PAN Card (Stipend Bank Linking)", "is_mandatory": True},
    ],
}


def generate_scheme_checklist(scheme: Any, user_docs: List[Any]) -> Dict[str, Any]:
    """Generates application readiness checklist for a given scheme and user documents."""
    docs_by_type = {doc.doc_type: doc for doc in user_docs}
    req_docs = REQUIRED_DOC_MAPPING.get(
        scheme.id,
        [
            {"doc_type": "Aadhaar", "title": "Aadhaar Card", "is_mandatory": True},
            {"doc_type": "IncomeCertificate", "title": "Income Certificate", "is_mandatory": False},
        ],
    )

    checklist_items = []
    total_required = len(req_docs)
    completed_count = 0

    for req in req_docs:
        dtype = req["doc_type"]
        user_doc = docs_by_type.get(dtype)

        if not user_doc:
            status = "Missing"
            masked = None
            notes = f"Upload valid {req['title']} to satisfy scheme requirements."
        elif user_doc.verification_status == "CorrectionRequired":
            status = "CorrectionRequired"
            masked = user_doc.masked_identifier
            notes = user_doc.verification_notes or "Re-upload document with matching profile information."
        elif user_doc.verification_status == "Warning":
            status = "Warning"
            masked = user_doc.masked_identifier
            notes = user_doc.verification_notes or "Minor difference noted. Verify document before submission."
            completed_count += 1
        else:
            status = "Available"
            masked = user_doc.masked_identifier
            notes = "Verified and ready for application submission."
            completed_count += 1

        checklist_items.append({
            "doc_type": dtype,
            "title": req["title"],
            "is_mandatory": req["is_mandatory"],
            "status": status,
            "masked_identifier": masked,
            "notes": notes,
        })

    readiness_percentage = round((completed_count / max(1, total_required)) * 100.0, 1)

    steps = [
        "1. Complete and verify student profile details.",
        "2. Upload and verify mandatory documents (Aadhaar, Income Certificate, PAN).",
        "3. Review AI-generated eligibility checklist and clear any warning flags.",
        f"4. Visit official portal ({scheme.sources[0].url if scheme.sources else 'https://myscheme.gov.in'}) to complete official submission.",
    ]

    return {
        "scheme_id": scheme.id,
        "scheme_title": scheme.title,
        "readiness_percentage": readiness_percentage,
        "is_ready_for_application": readiness_percentage == 100.0,
        "items": checklist_items,
        "application_steps": steps,
    }
