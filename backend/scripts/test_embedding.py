"""Test embedding API + retrieval pipeline directly."""
import asyncio
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///./schemora_dev.db")

async def main():
    from app.services.embedding_service import generate_embedding, embed_text, _tfidf_vector
    from app.core.config import settings
    
    print("="*60)
    print("EMBEDDING SERVICE DIAGNOSTIC")
    print("="*60)
    
    api_key = settings.GEMINI_API_KEY
    model = getattr(settings, "GEMINI_EMBEDDING_MODEL", "gemini-embedding-001")
    print(f"API Key: {api_key[:10]}... (len={len(api_key)})")
    print(f"Key starts with AIzaSy: {api_key.startswith('AIzaSy')}")
    print(f"Key starts with AQ: {api_key.startswith('AQ')}")
    print(f"Embedding Model: {model}")
    
    # Test Gemini embedding
    print("\n--- Testing Gemini Embedding API ---")
    test_text = "scholarship for OBC students in Maharashtra"
    
    import httpx
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:embedContent?key={api_key}"
    payload = {
        "model": f"models/{model}",
        "content": {"parts": [{"text": test_text}]},
    }
    
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(url, json=payload, headers={"Content-Type": "application/json"})
        print(f"HTTP Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json()
            emb = data.get("embedding", {}).get("values", [])
            print(f"SUCCESS! Embedding dimensions: {len(emb)}")
            if emb:
                print(f"First 5 values: {emb[:5]}")
        else:
            print(f"FAILED: {resp.text[:500]}")
    except Exception as e:
        print(f"EXCEPTION: {e}")
    
    # Test embed_text function
    print("\n--- Testing embed_text() function ---")
    emb, is_semantic = await embed_text(test_text)
    print(f"is_semantic={is_semantic}, emb_type={type(emb).__name__}, len={len(emb)}")
    
    # Test TF-IDF retrieval quality
    print("\n--- TF-IDF Retrieval Quality Test ---")
    
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
    from sqlalchemy.orm import sessionmaker
    from app.services.retrieval_service import retrieve_relevant_chunks
    
    engine = create_async_engine("sqlite+aiosqlite:///./schemora_dev.db", echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    test_queries = [
        "scholarships for OBC students",
        "scholarship application process",
        "documents required for scholarship",
        "how to apply for CSSS",
        "government schemes for students",
        "scholarships in Maharashtra",
        "OBC students financial help",
        "Tell me schemes related to OBC students",
    ]
    
    async with async_session() as db:
        for q in test_queries:
            chunks = await retrieve_relevant_chunks(db, q, top_k=3)
            print(f"\nQ: '{q}'")
            print(f"  Retrieved: {len(chunks)} chunks")
            for c in chunks[:2]:
                print(f"    Score={c['similarity_score']:.4f} | {c['scheme_name'][:40]} | section={c['section']}")
    
    print("\n" + "="*60)
    print("EMBEDDING DIAGNOSTIC COMPLETE")
    print("="*60)

asyncio.run(main())
