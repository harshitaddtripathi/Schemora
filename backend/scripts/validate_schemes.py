#!/usr/bin/env python3
"""
Validate Schemes Script (Step 4)
--------------------------------
Performs automated data quality checks on `backend/data/final/schemes.json`
and produces `backend/data/processed/validation_report.json`.
"""

import sys
import json
import logging
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.services.data_pipeline.cleaner import STATE_NAME_MAPPING

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("validate_schemes")


def run_validation() -> Path:
    final_json_path = backend_dir / "data" / "final" / "schemes.json"
    report_path = backend_dir / "data" / "processed" / "validation_report.json"

    if not final_json_path.exists():
        logger.error(f"Final dataset file {final_json_path} not found. Run normalize_schemes.py first.")
        sys.exit(1)

    with open(final_json_path, "r", encoding="utf-8") as f:
        schemes = json.load(f)

    total_schemes = len(schemes)
    valid_count = 0
    needs_review_count = 0
    duplicates_count = 0
    missing_source_count = 0

    issues = []
    seen_ids = set()
    seen_names = set()

    for idx, s in enumerate(schemes):
        scheme_id = s.get("scheme_id", "")
        scheme_name = s.get("scheme_name", "")
        govt_level = s.get("government_level", "")
        state = s.get("state")
        source = s.get("official_source", {}).get("name")
        last_verified = s.get("last_verified")
        desc = s.get("description", "")
        elig = s.get("eligibility", {})

        record_has_error = False

        # 1. Missing Name
        if not scheme_name:
            issues.append({"scheme_id": scheme_id, "type": "missing_name", "message": "Scheme name is empty"})
            record_has_error = True

        # 2. Duplicate Scheme ID
        if scheme_id in seen_ids:
            issues.append({"scheme_id": scheme_id, "type": "duplicate_id", "message": f"Duplicate scheme_id '{scheme_id}'"})
            duplicates_count += 1
            record_has_error = True
        else:
            seen_ids.add(scheme_id)

        # 3. Duplicate Scheme Name
        if scheme_name and scheme_name.lower() in seen_names:
            issues.append({"scheme_id": scheme_id, "type": "duplicate_name", "message": f"Duplicate scheme name '{scheme_name}'"})
            duplicates_count += 1
        else:
            if scheme_name:
                seen_names.add(scheme_name.lower())

        # 4. Invalid Government Level
        if govt_level not in ("central", "state"):
            issues.append({"scheme_id": scheme_id, "type": "invalid_govt_level", "message": f"Invalid government_level '{govt_level}'"})
            record_has_error = True

        # 5. Missing Source
        if not source or source == "Unknown":
            missing_source_count += 1
            issues.append({"scheme_id": scheme_id, "type": "missing_source", "message": "Missing official source name"})

        # 6. Missing Last Verified
        if not last_verified:
            issues.append({"scheme_id": scheme_id, "type": "missing_last_verified", "message": "Missing last_verified timestamp"})

        # 7. Empty Description
        if not desc:
            issues.append({"scheme_id": scheme_id, "type": "empty_description", "message": "Scheme description is empty"})
            record_has_error = True

        # 8. Age range check
        age = elig.get("age", {})
        min_age = age.get("min")
        max_age = age.get("max")
        if min_age is not None and max_age is not None and min_age > max_age:
            issues.append({"scheme_id": scheme_id, "type": "invalid_age_range", "message": f"min_age ({min_age}) > max_age ({max_age})"})
            record_has_error = True

        # Determine validity status
        if record_has_error:
            needs_review_count += 1
        else:
            valid_count += 1

    report = {
        "total_schemes": total_schemes,
        "valid": valid_count,
        "needs_review": needs_review_count,
        "duplicates": duplicates_count,
        "missing_source": missing_source_count,
        "total_issues_found": len(issues),
        "issues": issues,
    }

    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    logger.info(f"Validation complete: Total {total_schemes} | Valid: {valid_count} | Review required: {needs_review_count}")
    logger.info(f"Report saved to: {report_path}")
    return report_path


if __name__ == "__main__":
    run_validation()
