#!/usr/bin/env python3
"""
Ingest Schemes Script (Step 1)
------------------------------
Acquires raw government scheme data from configured authorized data sources 
and stores raw records in `backend/data/raw/schemes_raw.json`.

Follows strict data access rules: No unauthorized scraping.
"""

import sys
import json
import logging
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.services.data_pipeline.source_adapters import (
    MySchemeAuthorizedSource,
    DataGovSource,
    OfficialMinistrySource,
    OfficialStateSource,
    LocalRawFileSource,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("ingest_schemes")


def run_ingestion() -> Path:
    raw_dir = backend_dir / "data" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    raw_output_path = raw_dir / "schemes_raw.json"

    logger.info("Initializing Scheme Data Sources...")

    # Configure sources
    sources = []

    # 1. Official myScheme API adapter (requires API credentials in .env)
    sources.append(MySchemeAuthorizedSource())

    # 2. Data.gov.in official open data feed adapter
    sources.append(DataGovSource())

    # 3. Local authorized exports / seed dataset files
    local_files = [
        raw_dir / "schemes_input.json",
        raw_dir / "schemes_input.csv",
        backend_dir.parent / "data" / "schemes" / "schemes.v1.json",
        backend_dir / "data" / "raw" / "raw_export.json",
    ]
    sources.append(LocalRawFileSource(file_paths=local_files))

    all_raw_records = []
    for source in sources:
        records = source.fetch_schemes()
        logger.info(f"Source '{source.__class__.__name__}' provided {len(records)} raw records.")
        all_raw_records.extend(records)

    # Save to data/raw/schemes_raw.json
    logger.info(f"Writing {len(all_raw_records)} raw records to {raw_output_path}")
    with open(raw_output_path, "w", encoding="utf-8") as f:
        json.dump(all_raw_records, f, indent=2, ensure_ascii=False)

    logger.info(f"Ingestion complete. Raw dataset saved at: {raw_output_path}")
    return raw_output_path


if __name__ == "__main__":
    run_ingestion()
