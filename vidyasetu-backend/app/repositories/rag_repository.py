import math
from typing import Any, Dict, List, Optional
from pymongo.asynchronous.database import AsyncDatabase
from app.database.collections import get_rag_textbook_vectors_collection


def compute_cosine_similarity(vec_a: List[float], vec_b: List[float]) -> float:
    """Computes exact dot-product cosine similarity between two numeric vectors in Python."""
    if not vec_a or not vec_b or len(vec_a) != len(vec_b):
        return 0.0

    dot_product = sum(a * b for a, b in zip(vec_a, vec_b))
    norm_a = math.sqrt(sum(a * a for a in vec_a))
    norm_b = math.sqrt(sum(b * b for b in vec_b))

    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0

    return dot_product / (norm_a * norm_b)


async def get_chunks_by_chapter(
    db: AsyncDatabase, subject: str, chapter_name: str
) -> List[Dict[str, Any]]:
    """Retrieves all textbook chunks filtered by subject and chapter_name."""
    col = get_rag_textbook_vectors_collection(db)
    cursor = col.find(
        {
            "subject": subject.strip(),
            "chapter_name": chapter_name.strip(),
        }
    )
    return await cursor.to_list(length=None)


async def retrieve_top_k_chunks(
    db: AsyncDatabase,
    query_embedding: List[float],
    subject: str,
    chapter_name: str,
    k: int = 3,
) -> List[Dict[str, Any]]:
    """Chapter-scoped local cosine similarity top-k retriever in Python (NumPy/math fallback for local MongoDB).

    Filters candidate chunks by subject and chapter_name, computes cosine similarity against
    query_embedding, and returns the top-k highest scoring chunks with intact grounded citations.
    """
    candidates = await get_chunks_by_chapter(db, subject, chapter_name)
    if not candidates:
        return []

    scored_chunks = []
    for chunk in candidates:
        chunk_embedding = chunk.get("embedding", [])
        score = compute_cosine_similarity(query_embedding, chunk_embedding)
        chunk_copy = dict(chunk)
        chunk_copy["similarity_score"] = round(score, 4)
        scored_chunks.append(chunk_copy)

    # Sort descending by similarity score
    scored_chunks.sort(key=lambda x: x["similarity_score"], reverse=True)
    return scored_chunks[:k]


async def upsert_rag_chunk(db: AsyncDatabase, chunk_doc: Dict[str, Any]) -> None:
    """Idempotently upserts a textbook chunk into rag_textbook_vectors."""
    col = get_rag_textbook_vectors_collection(db)
    cid = chunk_doc.get("_id") or chunk_doc.get("chunk_id")
    if not cid:
        raise ValueError("Chunk document must contain '_id' or 'chunk_id'")
    doc_to_save = dict(chunk_doc)
    doc_to_save["_id"] = cid
    doc_to_save["chunk_id"] = cid
    await col.update_one({"_id": cid}, {"$set": doc_to_save}, upsert=True)
