import os
from sqlalchemy.orm import Session
from sqlalchemy import text
from openai import OpenAI


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
    db: Session,
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

def generate_recommendation(
    db: Session,
    doctor_message: str,
    surgery_type: str | None = None
) -> dict:
    """
    Full RAG pipeline:
    1. Retrieve relevant chunks
    2. Build context
    3. Call LLM with context
    4. Return answer + sources
    """

    # Step 1 — retrieve
    chunks = retrieve_relevant_chunks(db, doctor_message, surgery_type)

    # Step 2 — build context string
    context = "\n\n".join([
        f"[Source: {chunk['source']}]\n{chunk['content']}"
        for chunk in chunks
    ])

    sources = list(set([chunk["source"] for chunk in chunks]))

    # Step 3 — call LLM
    system_prompt = """You are a clinical assistant helping doctors write 
post-surgery recovery recommendations.

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

    user_prompt = f"""Context documents:
{context}

Doctor's request: {doctor_message}

Please suggest recovery recommendations based on the context above."""

    # Use OpenRouter locally, Bedrock in production
    provider = os.getenv("LLM_PROVIDER", "mock")

    if provider == "mock":
        reply = """Based on clinical guidelines, here are suggested recovery steps:

1. Avoid weight-bearing for 2 weeks post-surgery
2. Ice the area 3x daily for 20 minutes
3. Attend physiotherapy sessions twice a week from day 3
4. Monitor blood glucose closely (important for diabetic patients)
5. Watch for signs of infection: redness, swelling, fever above 38°C
6. Pain management: prescribed NSAIDs with meals
7. Follow-up appointment at 2 weeks and 6 weeks

Please review and adjust based on your clinical judgment."""

    elif provider == "openrouter":
        client = OpenAI(
            api_key=os.getenv("OPENROUTER_API_KEY"),
            base_url="https://openrouter.ai/api/v1"
        )
        response = client.chat.completions.create(
            model=os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini"),
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ]
        )
        reply = response.choices[0].message.content

    elif provider == "bedrock":
        import boto3
        import json
        bedrock = boto3.client("bedrock-runtime", region_name=os.getenv("AWS_REGION", "us-east-1"))
        response = bedrock.invoke_model(
            modelId="anthropic.claude-3-sonnet-20240229-v1:0",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "system": system_prompt,
                "messages": [{"role": "user", "content": user_prompt}]
            })
        )
        reply = json.loads(response["body"].read())["content"][0]["text"]

    return {
        "reply": reply,
        "sources": sources,
        "out_of_scope": False
    }