from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from openinference.instrumentation import using_attributes
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user
from app.providers.llm import get_llm_provider
from app.services.rag import generate_recommendation_stream

router = APIRouter(prefix="/ai", tags=["ai"])

GUARDRAIL_PREAMBLE = (
    "You are a post-surgery recovery assistant. Answer only using the patient's "
    "prescribed medications and recovery recommendations below. You are strictly "
    "informational: never diagnose, never suggest changing a dose or schedule, and "
    "never recommend a new medication. If asked to do any of those, say you can't "
    "and suggest contacting the clinician or emergency contact."
)

BLOCKED_INTENTS = {
    schemas.IntentCategory.dose_change_request,
    schemas.IntentCategory.diagnosis_request,
}


def _build_system_prompt(case: models.Case) -> str:
    meds = (
        "\n".join(
            f"- {m.name} {m.dose}, {m.schedule_text}, for {m.duration}" for m in case.medications
        )
        or "(no medications on file)"
    )
    recs = "\n".join(f"- {r.text}" for r in case.recommendations) or "(no recommendations on file)"

    return (
        f"{GUARDRAIL_PREAMBLE}\n\n"
        f"Prescribed medications:\n{meds}\n\n"
        f"Recovery recommendations:\n{recs}"
    )


def _check_guardrail(request: schemas.ChatRequest) -> tuple[bool, bool]:
    """Language-agnostic: blocks by intent_category enum, not English text."""
    if request.intent_category in BLOCKED_INTENTS:
        return False, True   # in_scope=False, escalate=True
    return True, False


def _process_chat_request(request: schemas.ChatRequest, db: Session) -> tuple[models.Case, bool, bool]:
    case = db.query(models.Case).filter(models.Case.id == request.case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    in_scope, escalate = _check_guardrail(request)
    return case, in_scope, escalate


@router.post("/chat", response_model=schemas.ChatResponse)
async def chat(
    request: schemas.ChatRequest,
    db: Session = Depends(get_db_for_user),
    _ = Depends(get_current_user),
):
    case, in_scope, escalate = _process_chat_request(request, db)

    db.add(
        models.ChatMessage(
            case_id=case.id,
            role=models.ChatRole.user,
            content=request.message,
            in_scope=in_scope,
            escalate=escalate,
        )
    )
    db.commit()

    if not in_scope:
        reply = (
            "I can't help with changing medication doses or schedules — that's a "
            "clinical decision. Please contact your clinician or use the emergency "
            "contact option for anything urgent."
        )
    else:
        provider = get_llm_provider()
        system_prompt = _build_system_prompt(case)
        with using_attributes(session_id=case.id, metadata={"endpoint": "ai.chat"}):
            reply = await provider.chat(
                messages=[{"role": "user", "content": request.message}],
                system=system_prompt,
            )

    db.add(
        models.ChatMessage(
            case_id=case.id,
            role=models.ChatRole.assistant,
            content=reply,
        )
    )
    db.commit()

    return schemas.ChatResponse(reply=reply, in_scope=in_scope, escalate=escalate)

@router.post("/chat/stream")
async def chat_stream(
    request: schemas.ChatRequest,
    db: Session = Depends(get_db_for_user),
    _ = Depends(get_current_user),
):
    case, in_scope, escalate = _process_chat_request(request, db)

    db.add(
        models.ChatMessage(
            case_id=case.id,
            role=models.ChatRole.user,
            content=request.message,
            in_scope=in_scope,
            escalate=escalate,
        )
    )
    db.commit()
    
    if not in_scope:
        async def mock_stream():
            reply = (
                "I can't help with changing medication doses or schedules — that's a "
                "clinical decision. Please contact your clinician or use the emergency "
                "contact option for anything urgent."
            )
            yield reply
            db.add(
                models.ChatMessage(
                    case_id=case.id,
                    role=models.ChatRole.assistant,
                    content=reply,
                )
            )
            db.commit()
        return StreamingResponse(mock_stream(), media_type="text/plain")

    async def stream_and_save():
        # Pass the surgery_type from case for RAG filter
        generator = generate_recommendation_stream(db, request.message, case.surgery_type)
        chunks = []
        async for chunk in generator:
            chunks.append(chunk)
            yield chunk
            
        db.add(
            models.ChatMessage(
                case_id=case.id,
                role=models.ChatRole.assistant,
                content="".join(chunks),
            )
        )
        db.commit()

    return StreamingResponse(stream_and_save(), media_type="text/plain")
