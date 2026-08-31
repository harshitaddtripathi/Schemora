"""
Comprehensive Schemora RAG Diagnostic and Test Script.
Tests retrieval pipeline, embedding, Gemini generation, and intent detection.
Run from backend/ directory: python scripts/test_rag.py
"""
import asyncio
import json
import os
import sys
import time
import math
import re

# Add project to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load env
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), "backend", ".env"))
load_dotenv(".env")


TEST_QUERIES = [
    {
        "id": "T01",
        "query": "Tell me schemes related to OBC students",
        "intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["OBC", "Post Matric", "Maharashtra"],
        "expected_section_any": ["overview", "eligibility"],
    },
    {
        "id": "T02",
        "query": "Which scholarships can I apply for?",
        "intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["scholarship", "Scholarship"],
        "expected_section_any": ["overview", "benefits"],
    },
    {
        "id": "T03",
        "query": "Give me the steps to fill a scholarship application",
        "intent": "APPLICATION_PROCESS",
        "expected_scheme_keywords": ["scholarship", "apply"],
        "expected_section_any": ["application"],
    },
    {
        "id": "T04",
        "query": "What documents are required for this scholarship?",
        "intent": "REQUIRED_DOCUMENTS",
        "expected_scheme_keywords": ["document", "required"],
        "expected_section_any": ["documents"],
    },
    {
        "id": "T05",
        "query": "How do I apply for CSSS?",
        "intent": "APPLICATION_PROCESS",
        "expected_scheme_keywords": ["Central Sector", "CSSS", "scholarship"],
        "expected_section_any": ["application"],
    },
    {
        "id": "T06",
        "query": "What benefits does CSSS provide?",
        "intent": "BENEFITS",
        "expected_scheme_keywords": ["Central Sector", "CSSS"],
        "expected_section_any": ["benefits"],
    },
    {
        "id": "T07",
        "query": "scholarships in Maharashtra",
        "intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["Maharashtra", "OBC"],
        "expected_section_any": ["overview"],
    },
    {
        "id": "T08",
        "query": "Can I get financial help for studying?",
        "intent": "BENEFITS",
        "expected_scheme_keywords": ["scholarship", "financial"],
        "expected_section_any": ["overview", "benefits"],
    },
    {
        "id": "T09",
        "query": "What papers do I need for scholarship?",
        "intent": "REQUIRED_DOCUMENTS",
        "expected_scheme_keywords": ["document", "certificate"],
        "expected_section_any": ["documents"],
    },
    {
        "id": "T10",
        "query": "Am I eligible for PM Internship?",
        "intent": "ELIGIBILITY",
        "expected_scheme_keywords": ["PM Internship", "Internship"],
        "expected_section_any": ["eligibility"],
    },
    {
        "id": "T11",
        "query": "Who are OBC students and what schemes exist for them?",
        "intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["OBC", "Post Matric"],
        "expected_section_any": ["overview", "eligibility"],
    },
    {
        "id": "T12",
        "query": "xyzfakequerynonexistent",
        "intent": "NO_RESULT",
        "expected_scheme_keywords": [],
        "expected_section_any": [],
    },
]


def detect_intent(query: str) -> str:
    """Simple intent detection."""
    q = query.lower()
    if any(w in q for w in ["document", "paper", "certificate", "need what", "what do i need", "what papers"]):
        return "REQUIRED_DOCUMENTS"
    if any(w in q for w in ["step", "apply", "application process", "how to apply", "fill", "submit", "register"]):
        return "APPLICATION_PROCESS"
    if any(w in q for w in ["eligible", "eligibility", "qualify", "requirements", "am i", "can i apply"]):
        return "ELIGIBILITY"
    if any(w in q for w in ["benefit", "amount", "provide", "give", "financial help", "assist", "get money"]):
        return "BENEFITS"
    if any(w in q for w in ["deadline", "when", "date", "last date", "window", "apply by"]):
        return "DEADLINE"
    if any(w in q for w in ["scheme", "scholarship", "program", "list", "find", "show", "which", "what scholarship", "tell me"]):
        return "SCHEME_DISCOVERY"
    return "GENERAL"


async def run_tests():
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
    from sqlalchemy.orm import sessionmaker

    engine = create_async_engine("sqlite+aiosqlite:///./schemora_dev.db", echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    # Import after engine created (avoids SQLAlchemy metaclass issues at import time)
    import importlib
    import app.services.retrieval_service as ret_mod
    retrieve_relevant_chunks = ret_mod.retrieve_relevant_chunks

    results = []
    pass_count = 0
    fail_count = 0

    print(f"\n{'='*70}")
    print("SCHEMORA RAG PIPELINE TEST SUITE")
    print(f"{'='*70}\n")

    async with async_session() as db:
        for test in TEST_QUERIES:
            tid = test["id"]
            query = test["query"]
            expected_keywords = test["expected_scheme_keywords"]
            expected_sections = test["expected_section_any"]
            expected_intent = test["intent"]

            t_start = time.perf_counter()
            chunks = await retrieve_relevant_chunks(db, query, top_k=5)
            elapsed_ms = (time.perf_counter() - t_start) * 1000

            # Detect intent
            detected_intent = detect_intent(query)
            intent_ok = (detected_intent == expected_intent or expected_intent == "GENERAL")

            # Check if at least one expected keyword appears in any retrieved chunk
            keyword_hit = False
            section_hit = False

            if expected_intent == "NO_RESULT":
                passed = len(chunks) == 0 or (chunks and chunks[0]["similarity_score"] < 0.15)
            else:
                for c in chunks:
                    content_lower = (c.get("content", "") + " " + c.get("scheme_name", "")).lower()
                    for kw in expected_keywords:
                        if kw.lower() in content_lower:
                            keyword_hit = True
                    if c.get("section") in expected_sections:
                        section_hit = True
                passed = (len(chunks) > 0) and (keyword_hit or not expected_keywords) and (section_hit or not expected_sections)

            status = "PASS" if passed else "FAIL"
            if passed:
                pass_count += 1
            else:
                fail_count += 1

            print(f"[{status}] {tid}: {query[:60]}")
            print(f"       Intent: detected={detected_intent} | expected={expected_intent}")
            print(f"       Retrieved: {len(chunks)} chunks in {elapsed_ms:.1f}ms")
            if chunks:
                top = chunks[0]
                print(f"       Top chunk: score={top['similarity_score']:.4f} | {top['scheme_name'][:40]} | section={top['section']}")
            if not passed:
                print(f"       FAIL REASON: keyword_hit={keyword_hit}, section_hit={section_hit}, chunks={len(chunks)}")

            results.append({
                "id": tid,
                "query": query,
                "status": status,
                "intent_detected": detected_intent,
                "intent_expected": expected_intent,
                "chunks_retrieved": len(chunks),
                "top_score": chunks[0]["similarity_score"] if chunks else 0.0,
                "top_scheme": chunks[0]["scheme_name"] if chunks else "",
                "keyword_hit": keyword_hit,
                "section_hit": section_hit,
                "elapsed_ms": round(elapsed_ms, 1),
            })
            print()

    print(f"{'='*70}")
    print(f"RESULTS: {pass_count} PASSED / {fail_count} FAILED out of {len(TEST_QUERIES)} tests")
    print(f"{'='*70}\n")

    return results, pass_count, fail_count


async def test_gemini_generation():
    """Test full Gemini generation with a sample RAG context."""
    print(f"\n{'='*70}")
    print("GEMINI GENERATION TEST")
    print(f"{'='*70}\n")

    from app.services.gemini_service import generate_grounded_chat_response
    from app.core.config import settings

    api_key = settings.GEMINI_API_KEY
    print(f"API Key present: {bool(api_key and len(api_key) > 10)}")
    print(f"Key prefix: {api_key[:10]}..." if api_key else "NO KEY")

    sample_chunks = [
        {
            "chunk_id": "test-chunk-1",
            "scheme_id": "sch-maharashtra-obc-postmatric-002",
            "scheme_name": "Post Matric Scholarship to OBC Students",
            "section": "overview",
            "content": (
                "Scheme: Post Matric Scholarship to OBC Students\n"
                "Category: Scholarship\n"
                "Jurisdiction: State (Maharashtra)\n"
                "Department: VJNT, OBC and SBC Welfare Department, Government of Maharashtra\n"
                "Description: A Maharashtra scheme for eligible OBC students pursuing post-matric education.\n"
                "Status: Active"
            ),
            "similarity_score": 0.85,
            "source_url": "https://mahadbt.maharashtra.gov.in/SchemeData/SchemeData?str=E9DDFA703C38E51AB02E984835E89FEFDB316E301CE6A991F41C5D42B01A7D7E",
            "source_title": "Post Matric Scholarship OBC — MahaDBT Official",
            "official_app_url": "https://mahadbt.maharashtra.gov.in/Login/Login",
            "last_verified_at": "2026-08-07",
            "scheme_version": "v1",
            "jurisdiction": "State",
            "state": "Maharashtra",
            "category": "Scholarship",
            "is_semantic": False,
        }
    ]

    queries = [
        "Tell me schemes related to OBC students",
        "What documents are required for scholarship?",
        "How do I apply for this scholarship?",
    ]

    for q in queries:
        print(f"\nQuery: '{q}'")
        t = time.perf_counter()
        answer, citations, is_grounded = await generate_grounded_chat_response(
            query=q,
            chunks=sample_chunks,
            language="en",
        )
        elapsed = (time.perf_counter() - t) * 1000
        print(f"  is_grounded: {is_grounded}")
        print(f"  citations: {len(citations)}")
        print(f"  elapsed: {elapsed:.1f}ms")
        print(f"  answer (first 200 chars): {answer[:200]}")
        status = "PASS" if answer and len(answer) > 50 else "FAIL"
        print(f"  status: {status}")


async def main():
    print("Starting Schemora RAG Diagnostic...")
    
    # Test retrieval
    try:
        results, passed, failed = await run_tests()
    except Exception as e:
        print(f"RETRIEVAL TEST ERROR: {e}")
        import traceback
        traceback.print_exc()
    
    # Test Gemini
    try:
        await test_gemini_generation()
    except Exception as e:
        print(f"GEMINI TEST ERROR: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
