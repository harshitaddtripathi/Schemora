import argparse
import asyncio
import json
import logging
import os
import sys
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.services.seeder import seed_scheme_dataset
from app.services.gemini_schemes_generator import generate_schemes_with_gemini

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

DATASET_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "schemes" / "schemes.v1.json"


async def main():
    parser = argparse.ArgumentParser(description="Populate Schemora Knowledge Base using Gemini AI")
    parser.add_argument("--api-key", type=str, help="Gemini API Key", default=None)
    parser.add_argument("--categories", nargs="+", default=["Agriculture", "Scholarship", "Health", "SkillDevelopment", "WomenEmpowerment"])
    parser.add_argument("--count-per-category", type=int, default=2)

    args = parser.parse_args()

    api_key = args.api_key or settings.GEMINI_API_KEY or os.environ.get("GEMINI_API_KEY")

    # First, seed existing dataset in JSON file
    logger.info(f"Seeding existing dataset from {DATASET_PATH}...")
    async with AsyncSessionLocal() as db:
        initial_seeded = await seed_scheme_dataset(db, DATASET_PATH)
        logger.info(f"Seeded {initial_seeded} schemes from static dataset.")

    if not api_key:
        logger.warning("No GEMINI_API_KEY provided. Skipping Gemini dynamic generation. Set GEMINI_API_KEY in .env or pass --api-key.")
        return

    logger.info(f"Using Gemini API to generate schemes across categories: {args.categories}")

    # Load existing JSON file
    if DATASET_PATH.exists():
        with open(DATASET_PATH, "r", encoding="utf-8") as f:
            dataset_data = json.load(f)
    else:
        dataset_data = {"dataset_version": "v1", "schemes": []}

    existing_ids = {s["scheme_id"] for s in dataset_data.get("schemes", [])}
    new_generated_schemes = []

    for cat in args.categories:
        try:
            logger.info(f"Generating {args.count-per-category} schemes for category '{cat}'...")
            schemes = await generate_schemes_with_gemini(api_key=api_key, category=cat, count=args.count_per_category)
            for s in schemes:
                s_id = s.get("scheme_id", f"sch-{cat.lower()}-{len(existing_ids)+1}")
                if s_id not in existing_ids:
                    dataset_data["schemes"].append(s)
                    existing_ids.add(s_id)
                    new_generated_schemes.append(s)
                    logger.info(f"Added generated scheme: {s.get('scheme_name')} ({s_id})")
        except Exception as e:
            logger.error(f"Failed to generate schemes for category '{cat}': {e}")

    # Save back to JSON dataset file
    with open(DATASET_PATH, "w", encoding="utf-8") as f:
        json.dump(dataset_data, f, indent=2, ensure_ascii=False)

    logger.info(f"Updated {DATASET_PATH} with {len(new_generated_schemes)} new schemes.")

    # Seed the newly added schemes into database and RAG
    async with AsyncSessionLocal() as db:
        newly_seeded = await seed_scheme_dataset(db, DATASET_PATH)
        logger.info(f"Seeded {newly_seeded} new schemes into database and RAG index!")


if __name__ == "__main__":
    asyncio.run(main())
