import json
import math
import re
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.knowledge import KnowledgeDocument, KnowledgeChunk


def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    """Splits document text into overlapping chunks."""
    text = text.strip()
    if not text:
        return []

    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end]
        chunks.append(chunk)
        start += chunk_size - overlap

    return chunks


def compute_tfidf_vector(text: str) -> Dict[str, float]:
    words = re.findall(r"\w+", text.lower())
    total = max(1, len(words))
    freqs: Dict[str, int] = {}
    for w in words:
        freqs[w] = freqs.get(w, 0) + 1
    return {w: c / total for w, c in freqs.items()}


def cosine_similarity(v1: Dict[str, float], v2: Dict[str, float]) -> float:
    common_words = set(v1.keys()) & set(v2.keys())
    if not common_words:
        return 0.0

    dot_product = sum(v1[w] * v2[w] for w in common_words)
    norm1 = math.sqrt(sum(val ** 2 for val in v1.values()))
    norm2 = math.sqrt(sum(val ** 2 for val in v2.values()))

    if norm1 == 0 or norm2 == 0:
        return 0.0
    return dot_product / (norm1 * norm2)


async def ingest_document(
    db: AsyncSession,
    title: str,
    content: str,
    scheme_id: Optional[str] = None,
    source_url: Optional[str] = None,
    doc_type: str = "OfficialGuideline",
) -> KnowledgeDocument:
    doc = KnowledgeDocument(
        title=title,
        scheme_id=scheme_id,
        source_url=source_url,
        doc_type=doc_type,
    )
    db.add(doc)
    await db.flush()

    raw_chunks = chunk_text(content)
    for idx, chunk_content in enumerate(raw_chunks):
        tf_idf = compute_tfidf_vector(chunk_content)
        chunk_obj = KnowledgeChunk(
            document_id=doc.id,
            scheme_id=scheme_id,
            chunk_index=idx,
            content=chunk_content,
            page_number=1,
            metadata_json=json.dumps({"source_url": source_url or "", "title": title}),
            embedding_json=json.dumps(tf_idf),
        )
        db.add(chunk_obj)

    await db.commit()
    await db.refresh(doc)
    return doc


async def retrieve_relevant_chunks(
    db: AsyncSession,
    query: str,
    scheme_id: Optional[str] = None,
    top_k: int = 3,
) -> List[Dict[str, Any]]:
    stmt = select(KnowledgeChunk)
    if scheme_id:
        stmt = stmt.where((KnowledgeChunk.scheme_id == scheme_id) | (KnowledgeChunk.scheme_id == None))

    result = await db.execute(stmt)
    chunks = result.scalars().all()

    if not chunks:
        return []

    query_vec = compute_tfidf_vector(query)
    scored_chunks = []

    for c in chunks:
        c_vec = json.loads(c.embedding_json) if c.embedding_json else compute_tfidf_vector(c.content)
        score = cosine_similarity(query_vec, c_vec)
        meta = json.loads(c.metadata_json) if c.metadata_json else {}

        scored_chunks.append({
            "chunk_id": c.id,
            "scheme_id": c.scheme_id,
            "content": c.content,
            "similarity_score": round(score, 4),
            "source_url": meta.get("source_url", "https://myscheme.gov.in"),
            "source_title": meta.get("title", "Official Guideline"),
        })

    scored_chunks.sort(key=lambda x: x["similarity_score"], reverse=True)
    return scored_chunks[:top_k]
