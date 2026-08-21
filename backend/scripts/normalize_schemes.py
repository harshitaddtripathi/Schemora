#!/usr/bin/env python3
"""
Normalize Schemes Script (Step 3)
---------------------------------
Validates cleaned records using Pydantic, generates content hashes, and writes
the final structured datasets:
  - backend/data/final/schemes.json
  - backend/data/final/schemes.csv
  - backend/data/final/eligibility_rules.json
"""

import sys
import json
import csv
import logging
from pathlib import Path
from typing import List, Dict, Any

backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.schemas.schemas_normalized import NormalizedScheme
from app.services.data_pipeline.cleaner import calculate_content_hash

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("normalize_schemes")


def run_normalization():
    cleaned_path = backend_dir / "data" / "processed" / "schemes_cleaned.json"
    final_dir = backend_dir / "data" / "final"
    final_dir.mkdir(parents=True, exist_ok=True)

    json_out_path = final_dir / "schemes.json"
    csv_out_path = final_dir / "schemes.csv"
    rules_out_path = final_dir / "eligibility_rules.json"

    if not cleaned_path.exists():
        logger.error(f"Cleaned dataset {cleaned_path} not found. Run clean_schemes.py first.")
        sys.exit(1)

    with open(cleaned_path, "r", encoding="utf-8") as f:
        cleaned_records = json.load(f)

    validated_schemes: List[Dict[str, Any]] = []
    eligibility_rules_map: Dict[str, Any] = {}
    csv_rows: List[Dict[str, Any]] = []

    for item in cleaned_records:
        try:
            # Pydantic validation
            scheme_obj = NormalizedScheme.model_validate(item)
            scheme_dict = scheme_obj.model_dump()
            
            # Calculate content hash
            scheme_dict["content_hash"] = calculate_content_hash(scheme_dict)
            validated_schemes.append(scheme_dict)

            # Build eligibility_rules entry
            elig = scheme_dict["eligibility"]
            eligibility_rules_map[scheme_dict["scheme_id"]] = {
                "scheme_id": scheme_dict["scheme_id"],
                "scheme_name": scheme_dict["scheme_name"],
                "rules": {
                    "age": elig.get("age"),
                    "gender": elig.get("gender"),
                    "annual_income": elig.get("income"),
                    "states": elig.get("states"),
                    "occupation": elig.get("occupation"),
                    "education": elig.get("education"),
                    "social_category": elig.get("social_category"),
                    "disability": elig.get("disability"),
                },
                "needs_review": elig.get("needs_review", False),
            }

            # Build CSV row
            benefits_summary = "; ".join([b.get("description", "") for b in scheme_dict.get("benefits", [])])
            csv_rows.append({
                "scheme_id": scheme_dict["scheme_id"],
                "scheme_name": scheme_dict["scheme_name"],
                "government_level": scheme_dict["government_level"],
                "state": scheme_dict["state"] or "",
                "ministry": scheme_dict["ministry"],
                "department": scheme_dict["department"],
                "category": ", ".join(scheme_dict.get("category", [])),
                "description": scheme_dict["description"],
                "benefits": benefits_summary,
                "min_age": elig.get("age", {}).get("min"),
                "max_age": elig.get("age", {}).get("max"),
                "gender": ", ".join(elig.get("gender", [])),
                "income_limit": elig.get("income", {}).get("maximum"),
                "occupation": ", ".join(elig.get("occupation", [])),
                "education": ", ".join(elig.get("education", [])),
                "social_category": ", ".join(elig.get("social_category", [])),
                "disability": elig.get("disability"),
                "documents_required": ", ".join(scheme_dict.get("documents_required", [])),
                "application_process": scheme_dict.get("application", {}).get("process", ""),
                "application_url": scheme_dict.get("application", {}).get("url", ""),
                "official_url": scheme_dict.get("official_source", {}).get("url", ""),
                "source": scheme_dict.get("official_source", {}).get("name", ""),
                "last_verified": scheme_dict.get("last_verified", ""),
            })

        except Exception as e:
            logger.error(f"Validation error for scheme {item.get('scheme_id')}: {e}")

    # Write final/schemes.json
    with open(json_out_path, "w", encoding="utf-8") as f:
        json.dump(validated_schemes, f, indent=2, ensure_ascii=False)
    logger.info(f"Saved primary JSON dataset ({len(validated_schemes)} records) to {json_out_path}")

    # Write final/eligibility_rules.json
    with open(rules_out_path, "w", encoding="utf-8") as f:
        json.dump(eligibility_rules_map, f, indent=2, ensure_ascii=False)
    logger.info(f"Saved eligibility rules dataset to {rules_out_path}")

    # Write final/schemes.csv
    csv_fields = [
        "scheme_id",
        "scheme_name",
        "government_level",
        "state",
        "ministry",
        "department",
        "category",
        "description",
        "benefits",
        "min_age",
        "max_age",
        "gender",
        "income_limit",
        "occupation",
        "education",
        "social_category",
        "disability",
        "documents_required",
        "application_process",
        "application_url",
        "official_url",
        "source",
        "last_verified",
    ]

    with open(csv_out_path, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=csv_fields)
        writer.writeheader()
        writer.writerows(csv_rows)
    logger.info(f"Saved CSV dataset to {csv_out_path}")

    return json_out_path, csv_out_path, rules_out_path


if __name__ == "__main__":
    run_normalization()
