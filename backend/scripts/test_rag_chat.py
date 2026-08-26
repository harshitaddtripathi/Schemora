import asyncio
import json
import httpx

BASE_URL = "http://localhost:8000/api/v1/ai"

async def test_chat():
    test_queries = [
        {"question": "What scholarships are available for college students?", "language": "en"},
        {"question": "छात्रों के लिए कौन सी छात्रवृत्ति योजनाएं उपलब्ध हैं?", "language": "hi"},
        {"question": "What is the benefit amount under PM Kisan Samman Nidhi?", "language": "en"},
    ]

    async with httpx.AsyncClient(timeout=10.0) as client:
        print("\n--- 1. Testing Knowledge Base Status ---")
        res = await client.get(f"{BASE_URL}/knowledge-base/status")
        print(f"Status Response [{res.status_code}]:", json.dumps(res.json(), indent=2))

        print("\n--- 2. Testing RAG Assistant Chat Responses ---")
        for q in test_queries:
            q_text = q['question'].encode("ascii", errors="replace").decode("ascii")
            print(f"\nQuestion ({q['language']}): {q_text}")
            res = await client.post(f"{BASE_URL}/chat", json=q)
            if res.status_code == 200:
                data = res.json().get("data", {})
                print(f"Confidence Score: {data.get('confidence_score')}")
                print(f"Is Grounded: {data.get('is_grounded')}")
                print(f"Retrieved Schemes: {len(data.get('retrieved_schemes', []))}")
                print(f"Citations: {len(data.get('citations', []))}")
                ans = data.get("answer", "")
                print("Answer Preview:\n", ans.encode("ascii", errors="replace").decode("ascii")[:400])
                print("-" * 50)
            else:
                print(f"Error {res.status_code}: {res.text}")

if __name__ == "__main__":
    asyncio.run(test_chat())
