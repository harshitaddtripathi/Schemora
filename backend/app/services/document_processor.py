"""Document Processor — Admin-uploaded source text processing.

When an admin uploads official source text for a scheme, this module:
1. Detects and splits the text into semantic sections.
2. Creates chunks with metadata.
3. Embeds and stores them.

This is used by the admin knowledge/publish endpoint.
"""

import re
import logging
from typing import Dict, List, Any

logger = logging.getLogger(__name__)

# Section header patterns for auto-detection
SECTION_PATTERNS = {
    "eligibility": [
        r"eligib", r"who can apply", r"criteria", r"qualification",
        r"conditions", r"requirement",
    ],
    "benefits": [
        r"benefit", r"scholarship amount", r"financial", r"stipend",
        r"assistance", r"amount", r"what you get",
    ],
    "documents": [
        r"document", r"certificate", r"required", r"checklist",
        r"proof", r"attachment",
    ],
    "application": [
        r"how to apply", r"application process", r"steps", r"portal",
        r"apply", r"procedure", r"submission",
    ],
    "deadlines": [
        r"deadline", r"last date", r"window", r"period", r"schedule",
        r"dates", r"closes", r"opens",
    ],
}


def detect_section(text: str) -> str:
    """Detect the section type of a text paragraph."""
    lower = text.lower()
    for section, patterns in SECTION_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, lower):
                return section
    return "overview"


def split_into_sections(raw_text: str) -> List[Dict[str, str]]:
    """Split raw document text into labeled sections.

    Tries to detect section headers; falls back to paragraph-based splitting.
    """
    # Try splitting on common section headers
    sections = []
    paragraphs = [p.strip() for p in re.split(r"\n{2,}", raw_text) if p.strip()]

    if len(paragraphs) <= 1:
        # Single block — treat as overview
        return [{"section": "overview", "content": raw_text.strip()}]

    for para in paragraphs:
        section = detect_section(para)
        # Merge consecutive same-section paragraphs
        if sections and sections[-1]["section"] == section:
            sections[-1]["content"] += "\n" + para
        else:
            sections.append({"section": section, "content": para})

    return sections


def process_admin_document(
    raw_text: str,
    scheme_id: str,
    scheme_name: str,
    source_url: str = "",
    official_app_url: str = "",
    last_verified_at: str = "",
) -> List[Dict[str, Any]]:
    """Process admin-uploaded source text into knowledge chunks.

    Returns a list of chunk dicts ready for indexing.
    """
    sections = split_into_sections(raw_text)
    chunks = []

    for idx, sec in enumerate(sections):
        content = sec["content"].strip()
        if not content or len(content) < 20:
            continue

        chunks.append({
            "chunk_index": idx,
            "section": sec["section"],
            "content": content,
            "scheme_id": scheme_id,
            "scheme_name": scheme_name,
            "jurisdiction": "",
            "state": None,
            "category": "",
            "source_id": "",
            "official_info_url": source_url,
            "official_app_url": official_app_url,
            "last_verified_at": last_verified_at,
            "scheme_version": "admin-v1",
            "metadata_json": f'{{"source_url": "{source_url}", "title": "{scheme_name} — {sec["section"].title()}"}}',
        })

    logger.info(f"Processed admin document for {scheme_id}: {len(chunks)} sections")
    return chunks
