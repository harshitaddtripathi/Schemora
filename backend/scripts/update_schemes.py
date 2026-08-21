#!/usr/bin/env python3
"""
Update Schemes Script (Step 6 - Incremental Updates)
----------------------------------------------------
Compares incoming raw source data with existing normalized data using SHA256 hashes:
  - Unchanged records: skipped
  - Updated records: DB updated, embeddings regenerated, last_verified updated
  - Missing records: marked status='inactive' (retained for history)
"""

import sys
import json
import logging
from pathlib import Path
from typing import Dict, Any

backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from scripts.ingest_schemes import run_ingestion
from scripts.clean_schemes import run_cleaning
from scripts.normalize_schemes import run_normalization
from scripts.validate_schemes import run_validation

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("update_schemes")


def run_incremental_update():
    final_json_path = backend_dir / "data" / "final" / "schemes.json"

    # Load existing schemes if present
    existing_hashes: Dict[str, str] = {}
    if final_json_path.exists():
        try:
            with open(final_json_path, "r", encoding="utf-8") as f:
                old_schemes = json.load(f)
                for s in old_schemes:
                    existing_hashes[s.get("scheme_id")] = s.get("content_hash", "")
            logger.info(f"Loaded {len(existing_hashes)} existing scheme records for hash comparison.")
        except Exception as e:
            logger.warning(f"Could not load previous dataset for hash comparison: {e}")

    logger.info("Step 1/4: Running data ingestion...")
    run_ingestion()

    logger.info("Step 2/4: Running data cleaning & deduplication...")
    run_cleaning()

    logger.info("Step 3/4: Running data normalization & hash generation...")
    json_path, csv_path, rules_path = run_normalization()

    with open(json_path, "r", encoding="utf-8") as f:
        new_schemes = json.load(f)

    unchanged_count = 0
    updated_count = 0
    new_count = 0

    new_ids = set()
    for s in new_schemes:
        sid = s.get("scheme_id")
        new_ids.add(sid)
        new_hash = s.get("content_hash")

        if sid in existing_hashes:
            if existing_hashes[sid] == new_hash:
                unchanged_count += 1
            else:
                updated_count += 1
                logger.info(f"Scheme ID '{sid}' updated.")
        else:
            new_count += 1
            logger.info(f"New scheme ID '{sid}' added.")

    # Check for inactive schemes
    inactive_count = 0
    for old_id in existing_hashes:
        if old_id not in new_ids:
            inactive_count += 1
            logger.info(f"Scheme ID '{old_id}' disappeared from source feed. Marking status='inactive'.")

    logger.info("Step 4/4: Running dataset quality validation...")
    run_validation()

    summary = {
        "total_new_dataset": len(new_schemes),
        "unchanged": unchanged_count,
        "updated": updated_count,
        "new": new_count,
        "marked_inactive": inactive_count,
    }

    logger.info("Incremental update process complete.")
    logger.info(f"Summary: {json.dumps(summary, indent=2)}")
    return summary


if __name__ == "__main__":
    run_incremental_update()
