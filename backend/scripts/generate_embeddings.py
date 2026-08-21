#!/usr/bin/env python3
"""
Generate Embeddings Script (Step 5)
-----------------------------------
Generates structured text representations and vector embeddings for all schemes
in `backend/data/final/schemes.json` using Gemini API or fallback embedding generator.
"""

import sys
import os
import json
import logging
from pathlib import Path
from typing import Dict, Any

backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("generate_embeddings")


def construct_scheme_text_representation(scheme: Dict[str, Any]) -> str:
    name = scheme.get("scheme_name", "")
    desc = scheme.get("description", "")
    benefits_list = scheme.get("benefits", [])
    benefits_str = "\n".join([f"- {b.get('description', '')}" for b in benefits_list]) if benefits_list else "None specified"

    elig = scheme.get("eligibility", {})
    age = elig.get("age", {})
    income = elig.get("income", {})
    elig_lines = [
        f"Age Range: {age.get('min', 'Any')} to {age.get('max', 'Any')} years",
        f"Gender: {', '.join(elig.get('gender', ['all']))}",
        f"Max Income: {income.get('maximum', 'No limit')} {income.get('currency', 'INR')}",
        f"Categories: {', '.join(elig.get('social_category', ['All']))}",
        f"State Domicile: {', '.join(elig.get('states', ['All'])) if elig.get('states') else 'Central / All States'}",
    ]
    eligibility_str = "\n".join(elig_lines)

    docs_list = scheme.get("documents_required", [])
    docs_str = ", ".join(docs_list) if docs_list else "None specified"

    app = scheme.get("application", {})
    app_process = app.get("process", "") or "Apply through official portal"

    formatted_text = f"""Scheme: {name}

Description:
{desc}

Benefits:
{benefits_str}

Eligibility:
{eligibility_str}

Documents:
{docs_str}

Application Process:
{app_process}
"""
    return formatted_text.strip()


def run_embedding_generation():
    final_json_path = backend_dir / "data" / "final" / "schemes.json"
    embeddings_out_path = backend_dir / "data" / "processed" / "scheme_embeddings.json"

    if not final_json_path.exists():
        logger.error(f"Final dataset {final_json_path} not found. Run normalize_schemes.py first.")
        sys.exit(1)

    with open(final_json_path, "r", encoding="utf-8") as f:
        schemes = json.load(f)

    logger.info(f"Generating embeddings for {len(schemes)} schemes...")

    gemini_key = os.getenv("GEMINI_API_KEY", "")
    use_gemini = bool(gemini_key)

    if use_gemini:
        logger.info("GEMINI_API_KEY detected. Using Gemini text-embedding-004 model.")
    else:
        logger.info("GEMINI_API_KEY not configured. Generating structural text representations and fallback embeddings.")

    embeddings_data = []

    for idx, s in enumerate(schemes):
        scheme_id = s.get("scheme_id")
        text_repr = construct_scheme_text_representation(s)
        
        embedding_vec = None
        if use_gemini:
            try:
                import google.generativeai as genai
                genai.configure(api_key=gemini_key)
                result = genai.embed_content(
                    model="models/text-embedding-004",
                    content=text_repr,
                    task_type="retrieval_document",
                )
                embedding_vec = result.get("embedding", [])
            except Exception as e:
                logger.warning(f"Failed to generate Gemini embedding for {scheme_id}: {e}")

        embeddings_data.append({
            "scheme_id": scheme_id,
            "scheme_name": s.get("scheme_name"),
            "text_representation": text_repr,
            "embedding": embedding_vec,
            "has_vector": bool(embedding_vec),
        })

    with open(embeddings_out_path, "w", encoding="utf-8") as f:
        json.dump(embeddings_data, f, indent=2, ensure_ascii=False)

    logger.info(f"Embeddings saved to: {embeddings_out_path}")
    return embeddings_out_path


if __name__ == "__main__":
    run_embedding_generation()
