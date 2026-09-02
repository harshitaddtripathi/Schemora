import asyncio
import sys
from app.services.gemini_service import generate_grounded_chat_response
from app.services.retrieval_service import detect_intent

sys.stdout.reconfigure(encoding='utf-8')

async def main():
    queries = [
        ("hi", "en"),
        ("hello!", "en"),
        ("namaste", "hi"),
        ("thanks", "en"),
        ("dhanyawad", "hi"),
        ("who are you", "en"),
    ]

    for q, lang in queries:
        intent = detect_intent(q)
        answer, citations, is_grounded = await generate_grounded_chat_response(q, [], language=lang)
        print(f"Query: '{q}' (lang={lang}, intent={intent})")
        print(f"Response: {answer}\n")

if __name__ == "__main__":
    asyncio.run(main())
