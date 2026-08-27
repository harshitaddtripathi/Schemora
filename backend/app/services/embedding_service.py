"""Embedding service for Schemora RAG pipeline.

Generates semantic vector embeddings using the Gemini text-embedding-004 API.
Falls back to a lightweight TF-IDF representation when Gemini is unavailable
(expired OAuth2 token, network error, quota exceeded).

Architecture decision: We store embeddings as JSON float arrays in the
existing SQLite `embedding_json` column. Cosine similarity is computed in
Python at query time. This is fast enough for the current dataset size
(~20 schemes × ~7 chunks = ~140 chunks).
"""

import os
import json
import math
import re
import logging
import httpx
from typing import List, Dict, Optional, Union

from app.core.config import settings

logger = logging.getLogger(__name__)

GEMINI_EMBEDDING_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:embedContent"
)

# Singleton cache: content_hash -> embedding list
# Avoids re-embedding identical text within the same process lifetime
_embedding_cache: Dict[str, List[float]] = {}
_api_disabled: bool = False


def _get_api_key() -> str:
    return os.getenv("GEMINI_API_KEY") or settings.GEMINI_API_KEY or ""


def _get_embedding_model() -> str:
    return getattr(settings, "GEMINI_EMBEDDING_MODEL", "text-embedding-004")


# ── TF-IDF fallback ───────────────────────────────────────────────────────────

def _tfidf_vector(text: str) -> Dict[str, float]:
    """Lightweight TF-IDF word frequency vector."""
    words = re.findall(r"\w+", text.lower())
    total = max(1, len(words))
    freqs: Dict[str, int] = {}
    for w in words:
        freqs[w] = freqs.get(w, 0) + 1
    return {w: c / total for w, c in freqs.items()}


def cosine_similarity_tfidf(v1: Dict[str, float], v2: Dict[str, float]) -> float:
    """Cosine similarity between two TF-IDF dicts."""
    common = set(v1) & set(v2)
    if not common:
        return 0.0
    dot = sum(v1[w] * v2[w] for w in common)
    n1 = math.sqrt(sum(x ** 2 for x in v1.values()))
    n2 = math.sqrt(sum(x ** 2 for x in v2.values()))
    if n1 == 0 or n2 == 0:
        return 0.0
    return dot / (n1 * n2)


def cosine_similarity_dense(v1: List[float], v2: List[float]) -> float:
    """Cosine similarity between two dense float vectors."""
    if len(v1) != len(v2) or not v1:
        return 0.0
    dot = sum(a * b for a, b in zip(v1, v2))
    n1 = math.sqrt(sum(a ** 2 for a in v1))
    n2 = math.sqrt(sum(b ** 2 for b in v2))
    if n1 == 0 or n2 == 0:
        return 0.0
    return dot / (n1 * n2)


def is_dense_embedding(data: Union[Dict, List, None]) -> bool:
    """Returns True if the stored embedding is a dense float list."""
    return isinstance(data, list) and len(data) > 10


# ── Gemini embedding call ─────────────────────────────────────────────────────

async def generate_embedding(text: str) -> Optional[List[float]]:
    """Generate a semantic embedding for `text` using the Gemini API.

    Returns a list of floats (768 dimensions for text-embedding-004),
    or None if the API call fails or is unconfigured.
    """
    global _api_disabled
    if _api_disabled:
        return None

    text = text.strip()
    if not text:
        return None

    # Cache hit
    cache_key = text[:500]
    if cache_key in _embedding_cache:
        return _embedding_cache[cache_key]

    api_key = _get_api_key()
    if not api_key or len(api_key) < 10:
        _api_disabled = True
        logger.debug("No valid Gemini API key — using fast TF-IDF fallback for embeddings")
        return None

    model = _get_embedding_model()
    url_template = GEMINI_EMBEDDING_URL.format(model=model)

    payload = {
        "model": f"models/{model}",
        "content": {"parts": [{"text": text[:2000]}]},  # API limit
    }

    try:
        url = f"{url_template}?key={api_key}"
        headers = {"Content-Type": "application/json"}

        async with httpx.AsyncClient(timeout=4.0) as client:
            resp = await client.post(url, json=payload, headers=headers)

        if resp.status_code == 200:
            data = resp.json()
            embedding = data.get("embedding", {}).get("values", [])
            if embedding:
                _embedding_cache[cache_key] = embedding
                return embedding
            else:
                logger.warning("Gemini embedding response missing values")
                return None
        elif resp.status_code in (401, 403):
            logger.warning(f"Gemini embedding API error {resp.status_code} (invalid key) — disabling remote embedding calls for process session.")
            _api_disabled = True
            return None
        else:
            logger.warning(f"Gemini embedding API error {resp.status_code}: {resp.text[:200]}")
            return None

    except Exception as e:
        logger.error(f"Gemini embedding call failed: {e}")
        return None


def embedding_to_json(embedding: Union[List[float], Dict[str, float], None]) -> str:
    """Serialize an embedding (dense list or TF-IDF dict) to JSON string."""
    if embedding is None:
        return json.dumps({})
    return json.dumps(embedding)


def json_to_embedding(json_str: Optional[str]) -> Union[List[float], Dict[str, float], None]:
    """Deserialize an embedding from its stored JSON string."""
    if not json_str:
        return None
    try:
        return json.loads(json_str)
    except Exception:
        return None


async def embed_text(text: str) -> tuple[Union[List[float], Dict[str, float]], bool]:
    """Embed text. Returns (embedding, is_semantic).

    is_semantic=True means a dense Gemini embedding was returned.
    is_semantic=False means TF-IDF fallback was used.
    """
    dense = await generate_embedding(text)
    if dense:
        return dense, True
    # Fallback to TF-IDF
    return _tfidf_vector(text), False
