#!/usr/bin/env python3
"""
Clean Schemes Script (Step 2)
-----------------------------
Reads raw scheme records from `backend/data/raw/schemes_raw.json`, cleans fields,
applies normalization rules, removes duplicates, and outputs `backend/data/processed/schemes_cleaned.json`.
"""

import sys
import json
import logging
from pathlib import Path
from typing import List, Dict, Any

backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.services.data_pipeline.cleaner import (
    normalize_string,
    normalize_state,
    normalize_government_level,
    normalize_gender,
    normalize_social_category,
    parse_income_amount,
    parse_age_range,
    normalize_url,
    normalize_slug,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("clean_schemes")


def clean_raw_records(raw_records: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    cleaned_records = []
    seen_source_ids = set()
    seen_name_combos = set()
    duplicate_count = 0

    for idx, item in enumerate(raw_records):
        source = item.get("source", "Unknown")
        source_id = str(item.get("source_id") or "").strip()
        raw = item.get("raw_data", {})

        # Extract title/name
        title = normalize_string(raw.get("scheme_name") or raw.get("title") or raw.get("name"))
        if not title:
            logger.warning(f"Record #{idx} missing scheme name. Skipping.")
            continue

        # 1. Source ID Duplicate Check
        if source_id and (source, source_id) in seen_source_ids:
            logger.info(f"Duplicate source ID skipped: {source}:{source_id}")
            duplicate_count += 1
            continue

        # Extract state and jurisdiction
        state = normalize_state(raw.get("state"))
        govt_level = normalize_government_level(raw.get("government_level") or raw.get("jurisdiction"), state)

        ministry = normalize_string(raw.get("ministry") or raw.get("department") or raw.get("provider"))
        dept = normalize_string(raw.get("department") or "")

        # 2. Name + Ministry + State Duplicate Check
        combo_key = f"{title.lower()}|{ministry.lower()}|{str(state).lower()}"
        if combo_key in seen_name_combos:
            logger.info(f"Duplicate scheme name/combo skipped: '{title}'")
            duplicate_count += 1
            continue

        if source_id:
            seen_source_ids.add((source, source_id))
        seen_name_combos.add(combo_key)

        scheme_id = str(raw.get("scheme_id") or source_id or f"sch-{govt_level[:4]}-{normalize_slug(title)[:20]}-{idx+1:04d}")

        description = normalize_string(raw.get("description") or raw.get("short_description"))

        # Category normalization
        raw_cat = raw.get("category") or raw.get("scheme_category") or []
        if isinstance(raw_cat, str):
            categories = [c.strip() for c in raw_cat.split(",") if c.strip()]
        elif isinstance(raw_cat, list):
            categories = [str(c).strip() for c in raw_cat if str(c).strip()]
        else:
            categories = ["General"]

        # Benefits
        raw_benefits = raw.get("benefits", [])
        benefits = []
        if isinstance(raw_benefits, list):
            for b in raw_benefits:
                if isinstance(b, dict):
                    b_desc = normalize_string(b.get("description") or b.get("benefit_summary"))
                    b_amt = parse_income_amount(b.get("amount"))
                    b_type = normalize_string(b.get("benefit_type") or "Financial")
                    benefits.append({
                        "description": b_desc,
                        "amount": b_amt,
                        "currency": b.get("currency") or "INR",
                        "benefit_type": b_type or "Financial",
                    })
                elif isinstance(b, str):
                    benefits.append({
                        "description": normalize_string(b),
                        "amount": None,
                        "currency": "INR",
                        "benefit_type": "Financial",
                    })
        elif isinstance(raw_benefits, str):
            benefits.append({
                "description": normalize_string(raw_benefits),
                "amount": None,
                "currency": "INR",
                "benefit_type": "Financial",
            })

        # Eligibility
        raw_elig = raw.get("eligibility") or raw.get("eligibility_rules") or {}
        min_age, max_age = parse_age_range(
            raw_elig.get("age") if isinstance(raw_elig, dict) else raw.get("min_age") or raw.get("age")
        )
        if min_age is None and raw.get("min_age") is not None:
            min_age = float(raw["min_age"])
        if max_age is None and raw.get("max_age") is not None:
            max_age = float(raw["max_age"])

        income_max = parse_income_amount(
            raw_elig.get("income", {}).get("maximum") if isinstance(raw_elig, dict) and isinstance(raw_elig.get("income"), dict)
            else raw.get("income_limit") or raw.get("max_family_income")
        )

        gender = normalize_gender(
            raw_elig.get("gender") if isinstance(raw_elig, dict)
            else raw.get("gender") or raw.get("gender_eligibility")
        )

        social_cat = normalize_social_category(
            raw_elig.get("social_category") if isinstance(raw_elig, dict)
            else raw.get("social_category") or raw.get("social_categories")
        )

        occupation = raw_elig.get("occupation", []) if isinstance(raw_elig, dict) else []
        if isinstance(occupation, str):
            occupation = [o.strip() for o in occupation.split(",") if o.strip()]

        education = raw_elig.get("education", []) if isinstance(raw_elig, dict) else []
        if isinstance(education, str):
            education = [e.strip() for e in education.split(",") if e.strip()]

        # Documents required
        raw_docs = raw.get("documents_required") or raw.get("required_documents") or []
        docs = []
        if isinstance(raw_docs, list):
            for d in raw_docs:
                if isinstance(d, dict):
                    doc_name = normalize_string(d.get("name") or d.get("document_type"))
                    if doc_name:
                        docs.append(doc_name)
                elif isinstance(d, str) and d.strip():
                    docs.append(d.strip())

        # Application Details
        app_url = normalize_url(raw.get("application_url") or raw.get("official_application_url") or raw.get("application", {}).get("url") if isinstance(raw.get("application"), dict) else None)
        official_url = normalize_url(raw.get("official_url") or raw.get("official_information_url") or raw.get("url") or app_url)
        app_process = normalize_string(
            raw.get("application_process") if isinstance(raw.get("application_process"), str)
            else str(raw.get("application_process", ""))
        )

        cleaned_records.append({
            "scheme_id": scheme_id,
            "scheme_name": title,
            "slug": normalize_slug(title),
            "government_level": govt_level,
            "state": state,
            "ministry": ministry,
            "department": dept,
            "category": categories,
            "description": description,
            "benefits": benefits,
            "eligibility": {
                "age": {"min": min_age, "max": max_age},
                "gender": gender,
                "income": {"minimum": None, "maximum": income_max, "currency": "INR"},
                "occupation": occupation,
                "education": education,
                "social_category": social_cat,
                "disability": raw_elig.get("disability") if isinstance(raw_elig, dict) else None,
                "marital_status": [],
                "residence": [],
                "states": [state] if state else [],
            },
            "documents_required": docs,
            "application": {
                "mode": ["Online"] if app_url else ["Offline"],
                "process": app_process,
                "url": app_url,
            },
            "official_source": {
                "name": source,
                "url": official_url,
                "source_id": source_id,
                "last_verified": raw.get("last_verified") or "2026-08-17T00:00:00Z",
                "verification_status": "verified",
            },
            "last_verified": raw.get("last_verified") or "2026-08-17T00:00:00Z",
        })

    logger.info(f"Cleaned {len(cleaned_records)} scheme records ({duplicate_count} duplicates removed).")
    return cleaned_records


def run_cleaning():
    raw_path = backend_dir / "data" / "raw" / "schemes_raw.json"
    processed_dir = backend_dir / "data" / "processed"
    processed_dir.mkdir(parents=True, exist_ok=True)
    out_path = processed_dir / "schemes_cleaned.json"

    if not raw_path.exists():
        logger.error(f"Raw data file {raw_path} not found. Run ingest_schemes.py first.")
        sys.exit(1)

    with open(raw_path, "r", encoding="utf-8") as f:
        raw_records = json.load(f)

    cleaned = clean_raw_records(raw_records)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, indent=2, ensure_ascii=False)

    logger.info(f"Cleaned data saved to: {out_path}")
    return out_path


if __name__ == "__main__":
    run_cleaning()
