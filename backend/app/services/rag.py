import os
import asyncio
import anyio
from sqlalchemy.orm import Session
from sqlalchemy import text
from openai import OpenAI, AsyncOpenAI

from app.core.database import SessionLocal

client_async = AsyncOpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1"
)


# ─────────────────────────────────────────
# Embedding
# ─────────────────────────────────────────

def get_embedding(text_input: str) -> list[float]:
    """
    Convert text into a vector using OpenAI embeddings.
    In production swap for Bedrock Titan embeddings.
    """
    client = OpenAI(
        api_key=os.getenv("OPENROUTER_API_KEY"),
        base_url="https://openrouter.ai/api/v1"
    )
    response = client.embeddings.create(
        model="openai/text-embedding-ada-002",
        input=text_input
    )
    return response.data[0].embedding


# ─────────────────────────────────────────
# Retrieval
# ─────────────────────────────────────────

def retrieve_relevant_chunks(
    query: str,
    surgery_type: str | None = None,
    top_k: int = 5
) -> list[dict]:
    """
    Embed the query and find the most similar chunks in pgvector.
    Optionally filter by surgery type.
    """
    query_embedding = get_embedding(query)
    embedding_str = str(query_embedding)

    with SessionLocal() as db:
        if surgery_type:
            sql = text("""
                SELECT content, source, source_type, surgery_type,
                       1 - (embedding <=> CAST(:embedding AS vector)) AS similarity
                FROM embeddings
                WHERE surgery_type = :surgery_type
                   OR surgery_type IS NULL
                ORDER BY embedding <=> CAST(:embedding AS vector)
                LIMIT :top_k
            """)
            rows = db.execute(sql, {
                "embedding": embedding_str,
                "surgery_type": surgery_type,
                "top_k": top_k
            }).fetchall()
        else:
            sql = text("""
                SELECT content, source, source_type, surgery_type,
                       1 - (embedding <=> CAST(:embedding AS vector)) AS similarity
                FROM embeddings
                ORDER BY embedding <=> CAST(:embedding AS vector)
                LIMIT :top_k
            """)
            rows = db.execute(sql, {
                "embedding": embedding_str,
                "top_k": top_k
            }).fetchall()

    return [
        {
            "content": row.content,
            "source": row.source,
            "source_type": row.source_type,
            "similarity": float(row.similarity)
        }
        for row in rows
    ]


# ─────────────────────────────────────────
# Generation
# ─────────────────────────────────────────

async def generate_recommendation_stream(doctor_message: str, surgery_type: str | None = None):
    chunks = await anyio.to_thread.run_sync(retrieve_relevant_chunks, doctor_message, surgery_type)
    context = "\n\n".join([f"[Source: {chunk['source']}]\n{chunk['content']}" for chunk in chunks])
    
    system_prompt = """You are a clinical assistant helping doctors write post-surgery recovery recommendations.
RULES:
- Base your answer ONLY on the provided context documents
- Never invent information not in the context
- Be specific and practical
- Format as a numbered list of steps
- Flag any drug interactions or warnings if relevant
- Never give diagnostic advice
- If context is insufficient, say so clearly
Always end with: "Please review and adjust based on your clinical judgment."
"""
    user_prompt = f"Context documents:\n{context}\n\nDoctor's request: {doctor_message}\n\nPlease suggest recovery recommendations based on the context above."

    response = await client_async.chat.completions.create(
        model=os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3-8b-instruct"),
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        stream=True
    )
    
    async for chunk in response:
        if chunk.choices and chunk.choices[0].delta.content:
            yield chunk.choices[0].delta.content