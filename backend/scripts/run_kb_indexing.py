import asyncio
import sys
from app.core.database import AsyncSessionLocal
from app.services.knowledge_base_service import index_all_schemes

sys.stdout.reconfigure(encoding='utf-8')

async def main():
    async with AsyncSessionLocal() as db:
        print("Starting knowledge base indexing from data/final/schemes.json...")
        res = await index_all_schemes(db)
        print("Indexing completed!")
        print(f"Total schemes: {res['total_schemes']}")
        print(f"Indexed schemes: {res['indexed_schemes']}")
        print(f"Total chunks created: {res['total_chunks']}")
        print(f"Semantic chunks: {res['semantic_chunks']}")
        print(f"TF-IDF chunks: {res['tfidf_chunks']}")

if __name__ == "__main__":
    asyncio.run(main())
