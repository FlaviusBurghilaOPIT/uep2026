import os
import asyncio
import anyio
from sqlalchemy.orm import Session
from sqlalchemy import text
from openai import OpenAI, AsyncOpenAI

from app.core.database import SessionLocal
from app.observability import track_llm_ops

client_async = AsyncOpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY") or "dummy-openrouter-key",
    base_url="https://openrouter.ai/api/v1"
)


# ─────────────────────────────────────────
# Embedding
# ─────────────────────────────────────────

@track_llm_ops(name="rag.embedding", model="openai/text-embedding-ada-002")
def get_embedding(text_input: str) -> list[float]:
    """
    Convert text into a vector using OpenAI / OpenRouter text embeddings.
    """
    api_key = os.getenv("OPENROUTER_API_KEY") or "dummy-openrouter-key"
    client = OpenAI(
        api_key=api_key,
        base_url="https://openrouter.ai/api/v1",
    )
    response = client.embeddings.create(
        model="openai/text-embedding-ada-002",
        input=text_input,
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
    try:
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
    except Exception:
        return []


# ─────────────────────────────────────────
# Generation
# ─────────────────────────────────────────

@track_llm_ops(name="rag.generate_recommendation_stream")
async def generate_recommendation_stream(
    doctor_message: str,
    surgery_type: str | None = None,
    patient_context: dict | None = None,
):
    chunks = await anyio.to_thread.run_sync(retrieve_relevant_chunks, doctor_message, surgery_type)
    guidelines_context = "\n\n".join([f"[Source: {chunk['source']}]\n{chunk['content']}" for chunk in chunks])
    
    if patient_context:
        # Patient-facing 24/7 recovery companion mode
        system_prompt = f"""You are RemoteCare Pro Assistant, an empathetic, supportive, and knowledgeable post-operative recovery companion.

PATIENT CONTEXT:
- Surgery: {patient_context.get('surgery_type', 'Post-Surgery')} (Status: {patient_context.get('case_status', 'Active')})
- Prescribed Medications: {patient_context.get('medications', 'None')}
- Clinician Instructions: {patient_context.get('recommendations', 'Follow doctor instructions')}
- Recent Symptom / Mood: {patient_context.get('recent_feeling', 'N/A')}
- Emergency Contact: {patient_context.get('emergency_contact', 'Clinician on file')}

CLINICAL GUIDELINES (RELEVANT REFERENCES):
{guidelines_context if guidelines_context else "Standard post-operative recovery care."}

SAFETY & INTERACTION RULES:
1. Strictly Informational: Never diagnose medical conditions and never recommend modifying prescription doses or stopping medications.
2. Context-Bound: Ground answers in the prescribed medications, doctor's recovery instructions, and clinical guidelines.
3. Multilingual (i18n): Automatically detect and respond in the language the patient uses (English, Spanish, Italian, etc.).
4. Empathy & Tone: Speak warmly, calmly, and clearly. Validate their feelings (e.g. pain, anxiety, tiredness) while providing reassuring, practical care tips.
5. Emergency Red Flags: If the user describes severe symptoms (uncontrolled bleeding, severe chest pain, shortness of breath, sudden leg swelling, fever > 38.5°C), urge them immediately to call emergency services or reach their emergency contact.
"""
        user_prompt = doctor_message
    else:
        # Clinician authoring assistant mode
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
        user_prompt = f"Context documents:\n{guidelines_context}\n\nDoctor's request: {doctor_message}\n\nPlease suggest recovery recommendations based on the context above."

    try:
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
    except Exception as err:
        fallback_reply = (
            "I am here to support your recovery. For questions about your specific medication doses "
            "or urgent symptoms, please reach out directly to your care team or emergency contact."
        )
        yield fallback_reply


@track_llm_ops(name="rag.generate_patients_summary", model=os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini"))
async def generate_patients_summary(patients_context: str) -> str:
    """Summarize a clinician's full patient roster (plain chat completion,
    no retrieval/embeddings involved)."""
    system_prompt = (
        "You are a clinical assistant summarizing a clinician's full patient roster. "
        "Write a concise, well-organized summary of overall status across all patients, "
        "followed by a 'Things to consider' section flagging any patients who may need "
        "extra attention (e.g. negative check-in feelings, no recent check-ins, or missing "
        "recovery recommendations). Never give diagnostic advice or suggest medication "
        "changes. Base your answer only on the data provided below."
    )
    response = await client_async.chat.completions.create(
        model=os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini"),
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Patient roster:\n\n{patients_context}\n\nPlease provide the summary."},
        ],
    )
    return response.choices[0].message.content
