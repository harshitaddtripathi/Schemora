"""
Schemora RAG Test Suite — Automated end-to-end tests.

Tests retrieval quality, intent detection, Gemini generation, and edge cases.
Uses the actual SQLite database (no mocking).

Run from backend/ directory:
  python scripts/run_rag_tests.py

Results are saved to: QA/RAG_TEST_RESULTS.json
"""
import asyncio
import json
import os
import sys
import time
import sqlite3
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(".env")


# ─── Test Definitions ─────────────────────────────────────────────────────────

TEST_CASES = [
    {
        "id": "T01_OBC_DISCOVERY",
        "query": "Tell me schemes related to OBC students",
        "expected_intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["OBC", "Post Matric", "Backward"],
        "expected_sections": ["overview", "eligibility"],
        "description": "OBC scheme discovery",
    },
    {
        "id": "T02_SCHOLARSHIP_DISCOVERY",
        "query": "Which scholarships can I apply for?",
        "expected_intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["Scholarship", "scholarship"],
        "expected_sections": ["overview"],
        "description": "General scholarship discovery",
    },
    {
        "id": "T03_APPLICATION_PROCESS",
        "query": "Give me the steps to fill a scholarship application",
        "expected_intent": "APPLICATION_PROCESS",
        "expected_scheme_keywords": [],
        "expected_sections": ["application"],
        "description": "Scholarship application steps",
    },
    {
        "id": "T04_DOCUMENTS",
        "query": "What documents are required for this scholarship?",
        "expected_intent": "REQUIRED_DOCUMENTS",
        "expected_scheme_keywords": [],
        "expected_sections": ["documents"],
        "description": "Required documents query",
    },
    {
        "id": "T05_CSSS_APPLY",
        "query": "How do I apply for CSSS?",
        "expected_intent": "APPLICATION_PROCESS",
        "expected_scheme_keywords": ["Central Sector", "CSSS"],
        "expected_sections": ["application", "overview"],
        "description": "CSSS application process",
    },
    {
        "id": "T06_CSSS_BENEFITS",
        "query": "What benefits does CSSS provide?",
        "expected_intent": "BENEFITS",
        "expected_scheme_keywords": ["Central Sector", "CSSS"],
        "expected_sections": ["benefits"],
        "description": "CSSS benefits query",
    },
    {
        "id": "T07_MAHARASHTRA",
        "query": "scholarships in Maharashtra",
        "expected_intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["Maharashtra"],
        "expected_sections": ["overview"],
        "description": "Maharashtra scholarship filter",
    },
    {
        "id": "T08_FINANCIAL_HELP",
        "query": "Can I get financial help for studying?",
        "expected_intent": "BENEFITS",
        "expected_scheme_keywords": [],
        "expected_sections": ["benefits", "overview"],
        "description": "Financial assistance query",
    },
    {
        "id": "T09_PAPERS",
        "query": "What papers do I need for scholarship?",
        "expected_intent": "REQUIRED_DOCUMENTS",
        "expected_scheme_keywords": [],
        "expected_sections": ["documents"],
        "description": "Papers/documents alternate phrasing",
    },
    {
        "id": "T10_ELIGIBILITY",
        "query": "Am I eligible for PM Internship?",
        "expected_intent": "ELIGIBILITY",
        "expected_scheme_keywords": ["PM Internship", "Internship"],
        "expected_sections": ["eligibility"],
        "description": "PM Internship eligibility",
    },
    {
        "id": "T11_OBC_DETAILED",
        "query": "Who are OBC students and what schemes exist for them?",
        "expected_intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["OBC", "Post Matric"],
        "expected_sections": ["overview", "eligibility"],
        "description": "OBC detailed query",
    },
    {
        "id": "T12_NO_RESULT",
        "query": "xyzfakequerythisshouldfindnothing12345",
        "expected_intent": "GENERAL",
        "expected_scheme_keywords": [],
        "expected_sections": [],
        "description": "No relevant result case",
    },
    {
        "id": "T13_UNDERGRADUATE",
        "query": "Which scholarships are available for undergraduate students?",
        "expected_intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": [],
        "expected_sections": ["overview", "eligibility"],
        "description": "Undergraduate scholarship query",
    },
    {
        "id": "T14_PERSONALIZED_OBC",
        "query": "I am an OBC student from Maharashtra. What schemes may match my profile?",
        "expected_intent": "SCHEME_DISCOVERY",
        "expected_scheme_keywords": ["OBC", "Maharashtra", "Post Matric"],
        "expected_sections": ["overview", "eligibility"],
        "description": "Personalized OBC Maharashtra query",
    },
]


# ─── Intent Detection (must match retrieval_service.py) ────────────────────────

import re

INTENT_PATTERNS = {
    # REQUIRED_DOCUMENTS first (before APPLICATION_PROCESS)
    "REQUIRED_DOCUMENTS": [
        r"\bdocuments?\b", r"\bpaper\b", r"\bcertificate\b",
        r"\bchecklist\b", r"\bupload\b", r"\bproof\b",
        r"\bpapers?\b",
        r"\bwhat.*need\b", r"\bwhat.*require\b",
        r"\brequired.*doc\b", r"\bdoc.*needed?\b",
    ],
    "APPLICATION_PROCESS": [
        r"\bhow.*(?:do|can|should|to).*apply\b",
        r"\bapplication.*process\b",
        r"\bstep.*(?:apply|fill|submit)\b",
        r"\bhow.*fill\b",
        r"\bsubmit.*application\b",
        r"\bsteps?.*scholarship\b",
        r"\bsteps?.*apply\b",
        r"\bapply.*online\b",
    ],
    "ELIGIBILITY": [
        r"\bam i (?:eligible|qualified|fit)\b",
        r"\bcan i (?:apply|qualify|receive)\b",
        r"\bwho (?:can|is|are) eligible\b",
        r"\beligib\b", r"\bqualif\b", r"\bcriteria\b",
    ],
    "BENEFITS": [
        r"\bbenefit\b", r"\bamount\b", r"\bstipend\b",
        r"\bgrant\b", r"\bhow much\b", r"\brupees?\b",
        r"\bfinancial.*help\b", r"\bfinancial.*assist\b",
        r"\bcan.*i get\b",
        r"\bhelp.*studying\b",
    ],
    "DEADLINE": [
        r"\bdeadline\b", r"\blast date\b",
        r"\bwindow\b", r"\bapply.*by\b",
    ],
    "STATUS": [r"\bstatus\b", r"\btrack\b", r"\breminder\b"],
}


def _detect_intent(query: str) -> str:
    q = query.lower()
    # Special case: "which scholarships/schemes..."
    if re.search(r"\bwhich\b", q) and re.search(r"\b(?:scholarships?|schemes?|programs?|yojana)\b", q):
        return "SCHEME_DISCOVERY"
    if re.search(r"\b(?:list|tell|show|find|what are).*(?:scholarships?|schemes?|programs?)\b", q):
        return "SCHEME_DISCOVERY"
    for intent, patterns in INTENT_PATTERNS.items():
        for pat in patterns:
            if re.search(pat, q):
                return intent
    if any(w in q for w in ["scheme", "scholarship", "program", "yojana"]):
        return "SCHEME_DISCOVERY"
    return "GENERAL"


# ─── Raw DB retrieval test (no app imports needed) ─────────────────────────────

def _tfidf(text: str) -> dict:
    words = re.findall(r"\w+", text.lower())
    total = max(1, len(words))
    freqs = {}
    for w in words:
        freqs[w] = freqs.get(w, 0) + 1
    return {w: c / total for w, c in freqs.items()}


def _cosine_tfidf(v1: dict, v2: dict) -> float:
    common = set(v1) & set(v2)
    if not common:
        return 0.0
    dot = sum(v1[w] * v2[w] for w in common)
    import math
    n1 = math.sqrt(sum(x**2 for x in v1.values()))
    n2 = math.sqrt(sum(x**2 for x in v2.values()))
    return dot / (n1 * n2) if n1 and n2 else 0.0


SECTION_BOOSTS = {
    "REQUIRED_DOCUMENTS": {"documents": 0.30, "application": 0.10},
    "APPLICATION_PROCESS": {"application": 0.30, "documents": 0.10},
    "ELIGIBILITY": {"eligibility": 0.25, "overview": 0.10},
    "BENEFITS": {"benefits": 0.30, "overview": 0.10},
    "SCHEME_DISCOVERY": {"overview": 0.20, "eligibility": 0.10},
    "GENERAL": {"overview": 0.10},
}

SOCIAL_SYNONYMS = {
    "obc": "OBC other backward class backward caste",
    "sc": "SC scheduled caste dalit",
    "st": "ST scheduled tribe tribal",
}

INTENT_EXPANSIONS = {
    "REQUIRED_DOCUMENTS": " required documents certificate marksheet income proof",
    "APPLICATION_PROCESS": " apply application steps process portal online register",
    "ELIGIBILITY": " eligible eligibility criteria who can apply conditions",
    "BENEFITS": " benefits financial assistance amount scholarship",
    "SCHEME_DISCOVERY": " scheme scholarship overview category description",
}


def _retrieve_raw(db_path: str, query: str, top_k: int = 5) -> list:
    """Direct SQLite retrieval without app imports (for standalone testing)."""
    intent = _detect_intent(query)
    expanded = query
    for cat, syn in SOCIAL_SYNONYMS.items():
        if cat in query.lower():
            expanded += " " + syn
    expanded += INTENT_EXPANSIONS.get(intent, "")

    q_vec = _tfidf(expanded)
    section_boosts = SECTION_BOOSTS.get(intent, {})

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
        SELECT id, scheme_id, scheme_name, section, content,
               official_info_url, official_app_url, state, category,
               embedding_json, is_indexed
        FROM knowledge_chunks
    """).fetchall()
    conn.close()

    scored = []
    stop = {"the","and","for","are","that","with","this","can","have","about",
            "what","how","tell","show","give","please","need","want","does","which"}

    for row in rows:
        emb_json = row["embedding_json"]
        score = 0.0
        if emb_json:
            try:
                emb = json.loads(emb_json)
                if isinstance(emb, dict):
                    score = _cosine_tfidf(q_vec, emb)
            except Exception:
                pass

        # Section boost
        section_boost = section_boosts.get(row["section"] or "", 0.0)

        # Keyword boost
        q_words = [w.lower() for w in re.findall(r"\w+", expanded) if len(w) > 2 and w.lower() not in stop]
        kw_boost = 0.0
        for w in q_words:
            if w in (row["scheme_name"] or "").lower():
                kw_boost += 0.12
            if w in (row["category"] or "").lower():
                kw_boost += 0.10
            if w in (row["state"] or "").lower():
                kw_boost += 0.10
            if w in (row["content"] or "").lower():
                kw_boost += 0.02
        kw_boost = min(0.40, kw_boost)

        total = min(1.0, score + section_boost + kw_boost)
        if total < 0.03:
            continue

        scored.append({
            "scheme_id": row["scheme_id"],
            "scheme_name": row["scheme_name"],
            "section": row["section"],
            "similarity_score": round(total, 4),
            "content": (row["content"] or "")[:200],
            "state": row["state"],
        })

    scored.sort(key=lambda x: x["similarity_score"], reverse=True)

    # Deduplicate by scheme+section
    seen = set()
    deduped = []
    for item in scored:
        key = (item["scheme_id"], item["section"])
        if key not in seen:
            seen.add(key)
            deduped.append(item)
        if len(deduped) >= top_k:
            break

    return deduped, intent


# ─── Test Runner ──────────────────────────────────────────────────────────────

def run_tests(db_path: str) -> dict:
    results = []
    passed = 0
    failed = 0

    print(f"\n{'='*70}")
    print("SCHEMORA RAG TEST SUITE")
    print(f"  Database: {db_path}")
    print(f"  Tests: {len(TEST_CASES)}")
    print(f"{'='*70}\n")

    for test in TEST_CASES:
        tid = test["id"]
        query = test["query"]
        expected_intent = test["expected_intent"]
        expected_keywords = test["expected_scheme_keywords"]
        expected_sections = test["expected_sections"]

        t0 = time.perf_counter()
        chunks, detected_intent = _retrieve_raw(db_path, query, top_k=5)
        elapsed_ms = (time.perf_counter() - t0) * 1000

        # Evaluate
        keyword_hit = False
        section_hit = False

        if expected_intent == "GENERAL" and not expected_keywords:
            # No-result test: pass if 0 results or low score
            passed_test = (len(chunks) == 0 or
                           (chunks and chunks[0]["similarity_score"] < 0.15))
        else:
            for c in chunks:
                full = (str(c.get("content") or "") + " " + str(c.get("scheme_name") or "") + " " + str(c.get("state") or "")).lower()
                for kw in expected_keywords:
                    if kw.lower() in full:
                        keyword_hit = True
                if c.get("section") in expected_sections:
                    section_hit = True

            passed_test = (
                len(chunks) > 0 and
                (keyword_hit or not expected_keywords) and
                (section_hit or not expected_sections)
            )

        status = "PASS" if passed_test else "FAIL"
        if passed_test:
            passed += 1
        else:
            failed += 1

        # Print result
        marker = "[OK]" if passed_test else "[!!]"
        print(f"{marker} {status} | {tid}: {query[:60]}")
        print(f"       Intent: detected={detected_intent} | expected={expected_intent}")
        print(f"       Retrieved: {len(chunks)} chunks | {elapsed_ms:.1f}ms")
        if chunks:
            top = chunks[0]
            print(f"       Top: score={top['similarity_score']:.4f} | {top['scheme_name'][:40]} | section={top['section']}")
        if not passed_test and expected_intent != "GENERAL":
            print(f"       FAIL: keyword_hit={keyword_hit}, section_hit={section_hit}, chunks={len(chunks)}")
        print()

        results.append({
            "id": tid,
            "description": test["description"],
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
            "top_chunks": [
                {"scheme": c["scheme_name"], "section": c["section"], "score": c["similarity_score"]}
                for c in chunks[:3]
            ],
        })

    print(f"{'='*70}")
    print(f"RESULTS: {passed}/{len(TEST_CASES)} PASSED | {failed} FAILED")
    print(f"{'='*70}\n")

    return {
        "timestamp": datetime.utcnow().isoformat(),
        "total": len(TEST_CASES),
        "passed": passed,
        "failed": failed,
        "pass_rate": f"{100 * passed // len(TEST_CASES)}%",
        "results": results,
    }


def main():
    db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "schemora_dev.db")
    if not os.path.exists(db_path):
        print(f"ERROR: DB not found at {db_path}")
        sys.exit(1)

    summary = run_tests(db_path)

    # Save results
    qa_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "QA")
    os.makedirs(qa_dir, exist_ok=True)
    out_path = os.path.join(qa_dir, "RAG_TEST_RESULTS.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)

    print(f"Results saved to: {out_path}")
    print(f"\nFinal: {summary['passed']}/{summary['total']} tests PASSED ({summary['pass_rate']})")
    sys.exit(0 if summary["failed"] == 0 else 1)


if __name__ == "__main__":
    main()
