"""
Re-index Schemora knowledge base with Gemini semantic embeddings.

This script should be run once to replace all TF-IDF embeddings with
proper Gemini dense embeddings (3072-dim).

Run from backend/ directory:
  python scripts/reindex_knowledge_base.py

The server does NOT need to be running. This runs standalone.
"""
import asyncio
import sys
import os
import time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv(".env")


async def main():
    print("="*60)
    print("SCHEMORA KNOWLEDGE BASE RE-INDEXER")
    print("="*60)

    # Import after setting env
    from app.core.config import settings
    from app.services.embedding_service import generate_embedding

    print(f"\nConfig:")
    print(f"  Database: {settings.DATABASE_URL}")
    print(f"  Gemini API Key: {settings.GEMINI_API_KEY[:10]}... (len={len(settings.GEMINI_API_KEY)})")
    print(f"  Embedding Model: {settings.GEMINI_EMBEDDING_MODEL}")

    # Test embedding first
    print("\n--- Testing Gemini Embedding API ---")
    test_emb = await generate_embedding("scholarship for OBC students")
    if test_emb:
        print(f"  SUCCESS: {len(test_emb)}-dim embedding generated")
    else:
        print("  FAILED: Could not generate embedding. Check API key.")
        print("  Tip: The key may need to be a valid 'AIzaSy...' key from https://aistudio.google.com/app/apikey")
        print("  Continuing anyway — will use TF-IDF for chunks where Gemini fails.")

    # Set up database
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
    from sqlalchemy.orm import sessionmaker

    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    # Import knowledge base service
    from app.services.knowledge_base_service import (
        index_all_schemes,
        get_knowledge_base_status,
        DATASET_PATH,
    )

    print(f"\n--- Dataset ---")
    print(f"  Path: {DATASET_PATH}")
    print(f"  Exists: {DATASET_PATH.exists()}")

    if not DATASET_PATH.exists():
        print("ERROR: Dataset file not found!")
        return

    import json
    with open(DATASET_PATH) as f:
        data = json.load(f)
    scheme_count = len(data.get("schemes", []))
    print(f"  Schemes in dataset: {scheme_count}")

    # Check current status
    async with async_session() as db:
        status = await get_knowledge_base_status(db)
        print(f"\n--- Current Knowledge Base Status ---")
        print(f"  Total chunks: {status['total_chunks']}")
        print(f"  Semantic chunks: {status['semantic_chunks']}")
        print(f"  TF-IDF chunks: {status['tfidf_chunks']}")
        print(f"  Indexed schemes: {status['indexed_schemes']}")
        print(f"  Is ready: {status['is_ready']}")

    confirm = input("\nProceed with full re-indexing? This will replace all existing chunks. [y/N]: ").strip().lower()
    if confirm != "y":
        print("Aborted.")
        return

    print("\n--- Starting Re-indexing ---")
    t_start = time.perf_counter()

    async with async_session() as db:
        result = await index_all_schemes(db)

    elapsed = time.perf_counter() - t_start
    print(f"\n--- Re-indexing Complete ---")
    print(f"  Total schemes: {result['total_schemes']}")
    print(f"  Indexed: {result['indexed_schemes']}")
    print(f"  Failed: {len(result['failed_schemes'])}")
    print(f"  Total chunks: {result['total_chunks']}")
    print(f"  Semantic chunks: {result['semantic_chunks']}")
    print(f"  TF-IDF chunks: {result['tfidf_chunks']}")
    print(f"  Time: {elapsed:.1f}s")
    if result['failed_schemes']:
        print(f"\n  FAILED SCHEMES:")
        for f in result['failed_schemes']:
            print(f"    {f['scheme_id']}: {f['error']}")

    # Verify
    async with async_session() as db:
        status = await get_knowledge_base_status(db)
        print(f"\n--- Final Status ---")
        print(f"  Total chunks: {status['total_chunks']}")
        print(f"  Semantic chunks: {status['semantic_chunks']}")
        print(f"  Embedding model: {status['embedding_model']}")
        print(f"  Is ready: {status['is_ready']}")

    print(f"\n{'='*60}")
    if status['semantic_chunks'] > 0:
        print("SUCCESS: Knowledge base re-indexed with semantic embeddings!")
    else:
        print("INFO: Knowledge base re-indexed with TF-IDF (Gemini API unavailable).")
        print("  The system will use intent-based TF-IDF retrieval.")
        print("  To enable semantic search, provide a valid GEMINI_API_KEY starting with 'AIzaSy'.")
    print(f"{'='*60}")


if __name__ == "__main__":
    asyncio.run(main())
