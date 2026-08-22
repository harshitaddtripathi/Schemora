"""Knowledge Base Service — Schemora RAG Phase 1.

Converts structured Phase 0 scheme JSON records into meaningful semantic
chunks that are then embedded and stored for retrieval.

Chunking strategy: NOT random character splits. Each scheme produces 7
section-level chunks with full metadata preserved per chunk:

  1. overview        — name, description, department, category
  2. benefits        — what you receive, amounts, frequency
  3. eligibility     — who can apply, rules in plain language
  4. documents       — required documents list
  5. application     — step-by-step how to apply, channels
  6. deadlines       — windows, cycles, opens/closes dates
  7. notes           — verification status, important caveats

Every chunk carries:
  scheme_id, scheme_name, section, jurisdiction, state, category,
  official_info_url, official_app_url, last_verified_at, scheme_version
"""

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete

from app.core.config import settings
from app.models.knowledge import KnowledgeDocument, KnowledgeChunk
from app.services.embedding_service import embed_text, embedding_to_json

logger = logging.getLogger(__name__)

DATASET_PATH = Path(__file__).resolve().parent.parent.parent.parent / "data" / "schemes" / "schemes.v1.json"

# Section labels
SECTION_OVERVIEW = "overview"
SECTION_BENEFITS = "benefits"
SECTION_ELIGIBILITY = "eligibility"
SECTION_DOCUMENTS = "documents"
SECTION_APPLICATION = "application"
SECTION_DEADLINES = "deadlines"
SECTION_NOTES = "notes"


# ── Chunk builders ────────────────────────────────────────────────────────────

def _build_overview_chunk(s: Dict[str, Any]) -> str:
    lines = [
        f"Scheme: {s.get('scheme_name', '')}",
        f"Category: {s.get('scheme_category', '')}",
        f"Jurisdiction: {s.get('jurisdiction', '')}",
    ]
    if s.get("state"):
        lines.append(f"State: {s['state']}")
    lines.append(f"Department: {s.get('department', '')}")
    desc = s.get("description") or s.get("short_description") or ""
    if desc:
        lines.append(f"Description: {desc[:800]}")
    lines.append(f"Status: {s.get('status', 'Active')}")
    return "\n".join(lines)


def _build_benefits_chunk(s: Dict[str, Any]) -> str:
    benefits = s.get("benefits", [])
    if not benefits:
        return f"Benefits for {s.get('scheme_name', '')}: Not yet fully verified. Check official portal."
    lines = [f"Benefits provided by {s.get('scheme_name', '')}:"]
    for b in benefits:
        desc = b.get("description", "")
        amount = b.get("amount")
        currency = b.get("currency", "INR")
        frequency = b.get("frequency", "")
        vstatus = b.get("verification_status", "")
        if amount:
            lines.append(f"  • {desc} — Amount: {currency} {amount} ({frequency})")
        else:
            lines.append(f"  • {desc} ({frequency})")
        if vstatus == "VerificationRequired":
            lines.append(f"    Note: Exact amount requires verification from official source.")
    return "\n".join(lines)


def _flatten_eligibility_conditions(conditions: List[Dict], depth: int = 0) -> List[str]:
    """Recursively flatten nested rule conditions into plain text lines."""
    lines = []
    indent = "  " * depth
    for cond in conditions:
        ctype = cond.get("type", "condition")
        if ctype == "condition":
            desc = cond.get("description", "")
            vstatus = cond.get("verification_status", "Verified")
            marker = "✓" if vstatus == "Verified" else "?"
            lines.append(f"{indent}{marker} {desc}")
        elif ctype in ("and", "or"):
            op_label = "All of the following" if ctype == "and" else "Any one of the following"
            lines.append(f"{indent}[{op_label}]:")
            sub = cond.get("conditions", [])
            lines.extend(_flatten_eligibility_conditions(sub, depth + 1))
    return lines


def _build_eligibility_chunk(s: Dict[str, Any]) -> str:
    lines = [f"Eligibility criteria for {s.get('scheme_name', '')}:"]

    rules = s.get("eligibility_rules", {})
    root = rules.get("root", {})
    conditions = root.get("conditions", [])

    if conditions:
        flat = _flatten_eligibility_conditions(conditions)
        lines.extend(flat)
    else:
        lines.append("Detailed eligibility criteria require verification from official portal.")

    # Append high-level filters if present
    for field, label in [
        ("gender_eligibility", "Gender"), ("social_categories", "Social Category"),
    ]:
        val = s.get(field)
        if val and val != "All":
            lines.append(f"  • {label}: {val}")

    return "\n".join(lines)


def _build_documents_chunk(s: Dict[str, Any]) -> str:
    docs = s.get("required_documents", [])
    lines = [f"Required documents for {s.get('scheme_name', '')}:"]
    if not docs:
        lines.append("Document checklist requires verification. Check official portal.")
        return "\n".join(lines)
    for d in docs:
        name = d.get("name", "")
        required = d.get("required", True)
        vstatus = d.get("verification_status", "Verified")
        marker = "✓" if vstatus == "Verified" else "?"
        req_label = "(Required)" if required else "(Optional)"
        lines.append(f"  {marker} {name} {req_label}")
    return "\n".join(lines)


def _build_application_chunk(s: Dict[str, Any]) -> str:
    steps = s.get("application_process", [])
    lines = [f"How to apply for {s.get('scheme_name', '')}:"]
    if s.get("official_application_url"):
        lines.append(f"Apply at: {s['official_application_url']}")
    if not steps:
        lines.append("Application process requires verification from official portal.")
        return "\n".join(lines)
    for step in sorted(steps, key=lambda x: x.get("step_number", 0)):
        n = step.get("step_number", "")
        desc = step.get("description", "")
        channel = step.get("channel", "")
        lines.append(f"  Step {n} ({channel}): {desc}")
    return "\n".join(lines)


def _build_deadlines_chunk(s: Dict[str, Any]) -> str:
    windows = s.get("application_windows", [])
    lines = [f"Application deadlines for {s.get('scheme_name', '')}:"]
    if s.get("application_cycle"):
        lines.append(f"Cycle: {s['application_cycle']}")
    if not windows:
        lines.append("Application window not announced. Check official portal for updates.")
        return "\n".join(lines)
    for w in windows:
        dtype = w.get("deadline_type", "")
        opens = w.get("opens_on") or "Not announced"
        closes = w.get("closes_on") or "Not announced"
        cycle = w.get("application_cycle", "")
        lines.append(f"  • Opens: {opens} | Closes: {closes} | Type: {dtype}")
        if cycle:
            lines.append(f"    Cycle: {cycle}")
    if s.get("application_deadline"):
        lines.append(f"Deadline: {s['application_deadline']}")
    return "\n".join(lines)


def _build_notes_chunk(s: Dict[str, Any]) -> str:
    verification = s.get("verification", {})
    overall = verification.get("overall_status", "Unknown")
    notes_text = verification.get("notes", "")
    required_fields = verification.get("verification_required_fields", [])
    verified_fields = verification.get("verified_fields", [])
    verified_at = s.get("verified_at", "")
    verified_by = s.get("verified_by", "")

    lines = [
        f"Important notes for {s.get('scheme_name', '')}:",
        f"Verification status: {overall}",
        f"Verified at: {verified_at}",
        f"Verified by: {verified_by}",
    ]
    if notes_text:
        lines.append(f"Note: {notes_text}")
    if verified_fields:
        lines.append(f"Verified fields: {', '.join(verified_fields[:5])}")
    if required_fields:
        lines.append(f"Fields requiring verification: {', '.join(required_fields[:5])}")
    lines.append(
        f"Official information: {s.get('official_information_url', 'Not available')}"
    )
    return "\n".join(lines)


# ── Main chunker ──────────────────────────────────────────────────────────────

SECTION_BUILDERS = [
    (SECTION_OVERVIEW, _build_overview_chunk),
    (SECTION_BENEFITS, _build_benefits_chunk),
    (SECTION_ELIGIBILITY, _build_eligibility_chunk),
    (SECTION_DOCUMENTS, _build_documents_chunk),
    (SECTION_APPLICATION, _build_application_chunk),
    (SECTION_DEADLINES, _build_deadlines_chunk),
    (SECTION_NOTES, _build_notes_chunk),
]


def build_chunks_for_scheme(s: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Build all semantic chunks for a single scheme dict.

    Returns a list of chunk dicts with content + metadata.
    """
    scheme_id = s.get("scheme_id", "")
    scheme_name = s.get("scheme_name", "")
    jurisdiction = s.get("jurisdiction", "Central")
    state = s.get("state")
    category = s.get("scheme_category", "")
    official_info_url = s.get("official_information_url", "")
    official_app_url = s.get("official_application_url", "")
    last_verified_at = s.get("verified_at", "")
    scheme_version = s.get("scheme_version", "v1")

    # Collect source IDs
    source_ids = s.get("source_documents", [])
    source_id = source_ids[0] if source_ids else ""

    chunks = []
    for idx, (section, builder) in enumerate(SECTION_BUILDERS):
        try:
            content = builder(s).strip()
            if not content:
                continue
            chunks.append({
                "chunk_index": idx,
                "section": section,
                "content": content,
                "scheme_id": scheme_id,
                "scheme_name": scheme_name,
                "jurisdiction": jurisdiction,
                "state": state,
                "category": category,
                "source_id": source_id,
                "official_info_url": official_info_url,
                "official_app_url": official_app_url,
                "last_verified_at": last_verified_at,
                "scheme_version": scheme_version,
                "metadata_json": json.dumps({
                    "source_url": official_info_url,
                    "title": f"{scheme_name} — {section.title()}",
                    "scheme_id": scheme_id,
                }),
            })
        except Exception as e:
            logger.warning(f"Failed to build {section} chunk for {scheme_id}: {e}")

    return chunks


# ── DB operations ─────────────────────────────────────────────────────────────

async def delete_scheme_knowledge(db: AsyncSession, scheme_id: str) -> int:
    """Delete all knowledge chunks and documents for a scheme. Returns chunk count removed."""
    chunks_result = await db.execute(
        select(KnowledgeChunk).where(KnowledgeChunk.scheme_id == scheme_id)
    )
    chunks = chunks_result.scalars().all()
    count = len(chunks)
    for c in chunks:
        await db.delete(c)

    docs_result = await db.execute(
        select(KnowledgeDocument).where(KnowledgeDocument.scheme_id == scheme_id)
    )
    for doc in docs_result.scalars().all():
        await db.delete(doc)

    await db.flush()
    return count


async def index_scheme(
    db: AsyncSession,
    scheme_data: Dict[str, Any],
    replace: bool = True,
) -> Tuple[int, int]:
    """Index a single scheme into the knowledge base.

    Args:
        db: Async DB session.
        scheme_data: Scheme dict from Phase 0 JSON.
        replace: If True, delete existing chunks first (idempotent re-index).

    Returns:
        (chunks_created, semantic_embeddings_count)
    """
    scheme_id = scheme_data.get("scheme_id", "")
    scheme_name = scheme_data.get("scheme_name", "Unknown")

    if replace:
        await delete_scheme_knowledge(db, scheme_id)

    # Create the parent document
    doc = KnowledgeDocument(
        scheme_id=scheme_id,
        title=f"{scheme_name} — Phase 0 Knowledge Base",
        source_url=scheme_data.get("official_information_url", ""),
        doc_type="Phase0Dataset",
    )
    db.add(doc)
    await db.flush()

    # Build semantic chunks
    raw_chunks = build_chunks_for_scheme(scheme_data)
    semantic_count = 0

    for chunk_dict in raw_chunks:
        content = chunk_dict["content"]
        embedding, is_semantic = await embed_text(content)
        if is_semantic:
            semantic_count += 1

        chunk_obj = KnowledgeChunk(
            document_id=doc.id,
            scheme_id=chunk_dict["scheme_id"],
            chunk_index=chunk_dict["chunk_index"],
            content=content,
            section=chunk_dict["section"],
            scheme_name=chunk_dict["scheme_name"],
            jurisdiction=chunk_dict["jurisdiction"],
            state=chunk_dict.get("state"),
            category=chunk_dict["category"],
            source_id=chunk_dict["source_id"],
            official_info_url=chunk_dict["official_info_url"],
            official_app_url=chunk_dict["official_app_url"],
            last_verified_at=chunk_dict["last_verified_at"],
            scheme_version=chunk_dict["scheme_version"],
            embedding_json=embedding_to_json(embedding),
            metadata_json=chunk_dict["metadata_json"],
            is_indexed=is_semantic,
            page_number=1,
        )
        db.add(chunk_obj)

    await db.commit()
    logger.info(
        f"Indexed scheme {scheme_id}: {len(raw_chunks)} chunks "
        f"({semantic_count} semantic, {len(raw_chunks) - semantic_count} TF-IDF)"
    )
    return len(raw_chunks), semantic_count


async def index_all_schemes(db: AsyncSession) -> Dict[str, Any]:
    """Load Phase 0 dataset and index all schemes.

    Returns a summary dict with counts.
    """
    if not DATASET_PATH.exists():
        raise FileNotFoundError(f"Dataset not found at {DATASET_PATH}")

    with open(DATASET_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    schemes = data.get("schemes", [])
    total_chunks = 0
    total_semantic = 0
    indexed_schemes = []
    failed_schemes = []

    for s in schemes:
        scheme_id = s.get("scheme_id", "unknown")
        try:
            chunks, semantic = await index_scheme(db, s, replace=True)
            total_chunks += chunks
            total_semantic += semantic
            indexed_schemes.append(scheme_id)
        except Exception as e:
            logger.error(f"Failed to index scheme {scheme_id}: {e}")
            failed_schemes.append({"scheme_id": scheme_id, "error": str(e)})

    return {
        "total_schemes": len(schemes),
        "indexed_schemes": len(indexed_schemes),
        "failed_schemes": failed_schemes,
        "total_chunks": total_chunks,
        "semantic_chunks": total_semantic,
        "tfidf_chunks": total_chunks - total_semantic,
        "dataset_version": data.get("dataset_version", "v1"),
    }


async def get_knowledge_base_status(db: AsyncSession) -> Dict[str, Any]:
    """Return current knowledge base statistics."""
    from sqlalchemy import func, distinct

    # Total chunks
    result = await db.execute(select(func.count(KnowledgeChunk.id)))
    total_chunks = result.scalar() or 0

    # Semantic (embedded) chunks
    result = await db.execute(
        select(func.count(KnowledgeChunk.id)).where(KnowledgeChunk.is_indexed == True)
    )
    semantic_chunks = result.scalar() or 0

    # Distinct schemes indexed
    result = await db.execute(
        select(func.count(distinct(KnowledgeChunk.scheme_id)))
        .where(KnowledgeChunk.scheme_id != None)
    )
    indexed_schemes = result.scalar() or 0

    # Documents
    result = await db.execute(select(func.count(KnowledgeDocument.id)))
    total_docs = result.scalar() or 0

    return {
        "total_chunks": total_chunks,
        "semantic_chunks": semantic_chunks,
        "tfidf_chunks": total_chunks - semantic_chunks,
        "indexed_schemes": indexed_schemes,
        "total_documents": total_docs,
        "embedding_model": getattr(settings, "GEMINI_EMBEDDING_MODEL", "text-embedding-004"),
        "is_ready": total_chunks > 0,
    }
