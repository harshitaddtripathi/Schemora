import asyncio
import sys
from app.core.database import AsyncSessionLocal
from app.services.retrieval_service import retrieve_relevant_chunks
from app.services.gemini_service import generate_grounded_chat_response

sys.stdout.reconfigure(encoding='utf-8')

async def test_query(query: str, lang: str = "en"):
    async with AsyncSessionLocal() as db:
        chunks = await retrieve_relevant_chunks(db, query)
        print(f"\n================ QUERY: '{query}' (Retrieved {len(chunks)} chunks) ================")
        for i, c in enumerate(chunks[:4], 1):
            print(f"  {i}. {c.get('scheme_name')} | Score: {c.get('similarity_score')}")

        answer, _, _ = await generate_grounded_chat_response(query, chunks, language=lang)
        print("\n--- RESPONSE ---")
        print(answer)

async def main():
    await test_query("give me schemes related to women")
    await test_query("give me schemes related to farmers")
    await test_query("what are health schemes available?")

if __name__ == "__main__":
    asyncio.run(main())
