from datetime import datetime, timedelta

import anyio
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session, selectinload

from app.core.database import SessionLocal
from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user, require_clinician
from app.services.rag import generate_recommendation_stream, generate_patients_summary

router = APIRouter(prefix="/ai", tags=["ai"])

# Chat is never deleted from Postgres (audit trail). It's soft-hidden by age
# instead: once a message passes this window it drops out of both the
# mobile/web history view and the LLM's conversation memory, so the patient
# sees a fresh conversation start without any row ever being removed.
CHAT_HISTORY_MAX_AGE = timedelta(days=4)

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


def _check_guardrail(request: schemas.ChatRequest) -> tuple[bool, bool]:
    """Language-agnostic: blocks by intent_category enum, not English text."""
    if request.intent_category in BLOCKED_INTENTS:
        return False, True   # in_scope=False, escalate=True
    return True, False


def _build_patient_context(case: models.Case) -> dict:
    active_meds = [
        f"{m.name} ({m.dose}, {getattr(m, 'schedule_text', '')})"
        for m in (getattr(case, "medications", None) or [])
        if getattr(m, "discontinued_at", None) is None
    ]
    recs = [r.text for r in (getattr(case, "recommendations", None) or [])]
    checkins = getattr(case, "checkins", None) or []
    sorted_checkins = sorted(checkins, key=lambda c: c.created_at, reverse=True) if checkins else []
    recent_feeling = (
        sorted_checkins[0].feeling.value if sorted_checkins and hasattr(sorted_checkins[0], "feeling") else "N/A"
    )
    emergency_contact = (
        f"{getattr(case, 'emergency_contact_name', None) or 'N/A'} ({getattr(case, 'emergency_contact_phone', None) or 'N/A'})"
    )
    return {
        "surgery_type": getattr(case, "surgery_type", None) or "Post-Surgery",
        "case_status": getattr(case, "status", None) or "Active",
        "medications": ", ".join(active_meds) if active_meds else "None",
        "recommendations": "; ".join(recs) if recs else "None",
        "recent_feeling": recent_feeling,
        "emergency_contact": emergency_contact,
    }


def _visible_messages_query(db, case_id: str, limit: int):
    cutoff = datetime.utcnow() - CHAT_HISTORY_MAX_AGE
    rows = (
        db.query(models.ChatMessage)
        .filter(
            models.ChatMessage.case_id == case_id,
            models.ChatMessage.created_at >= cutoff,
        )
        .order_by(models.ChatMessage.created_at.desc())
        .limit(limit)
        .all()
    )
    rows.reverse()
    return rows


def _get_case_context_and_history_sync(
    case_id: str, user_id: str, user_role: models.UserRole, limit: int = 20
) -> tuple[models.Case, dict, list[dict]] | None:
    """Case lookup + recent-history fetch in one `SessionLocal()`/one thread
    hop (not two) — two sequential `anyio.to_thread.run_sync` DB calls per
    request raced with the SQLite test fixture's session and detached its
    objects; one combined call doesn't."""
    with SessionLocal() as db:
        query = (
            db.query(models.Case)
            .options(
                selectinload(models.Case.medications),
                selectinload(models.Case.recommendations),
                selectinload(models.Case.checkins),
            )
            .filter(models.Case.id == case_id)
        )
        if user_role == models.UserRole.patient:
            query = query.filter(models.Case.patient_id == user_id)
        elif user_role == models.UserRole.clinician:
            query = query.filter(models.Case.clinician_id == user_id)

        case = query.first()
        if not case:
            return None
        ctx = _build_patient_context(case)
        history_rows = _visible_messages_query(db, case_id, limit)
        history = [
            {
                "role": "user" if row.role == models.ChatRole.user else "assistant",
                "content": row.content,
            }
            for row in history_rows
        ]
        db.expunge(case)
        return case, ctx, history


async def _process_chat_request(
    request: schemas.ChatRequest, current_user: models.User
) -> tuple[models.Case, dict, list[dict], bool, bool]:
    res = await anyio.to_thread.run_sync(
        _get_case_context_and_history_sync,
        request.case_id,
        current_user.id,
        current_user.role,
    )
    if not res:
        raise HTTPException(status_code=404, detail="Case not found")
    case, patient_ctx, history = res
    in_scope, escalate = _check_guardrail(request)
    return case, patient_ctx, history, in_scope, escalate


def _save_message_sync(message: models.ChatMessage):
    with SessionLocal() as db_sess:
        db_sess.add(message)
        db_sess.commit()
        db_sess.refresh(message)


async def _save_user_message(case_id: str, content: str, in_scope: bool, escalate: bool):
    await anyio.to_thread.run_sync(
        _save_message_sync,
        models.ChatMessage(
            case_id=case_id,
            role=models.ChatRole.user,
            content=content,
            in_scope=in_scope,
            escalate=escalate,
        )
    )


def _get_case_and_history_sync(
    case_id: str, user_id: str, user_role: models.UserRole, limit: int = 20
) -> tuple[models.Case, list[models.ChatMessage]] | None:
    """Case-ownership check + recent-history rows in one `SessionLocal()`/one
    thread hop, for the read-only history endpoint (see
    `_get_case_context_and_history_sync` for the chat-turn variant)."""
    with SessionLocal() as db:
        query = db.query(models.Case).filter(models.Case.id == case_id)
        if user_role == models.UserRole.patient:
            query = query.filter(models.Case.patient_id == user_id)
        elif user_role == models.UserRole.clinician:
            query = query.filter(models.Case.clinician_id == user_id)

        case = query.first()
        if not case:
            return None
        rows = _visible_messages_query(db, case.id, limit)
        db.expunge_all()
        return case, rows


async def _save_assistant_message_shielded(case_id: str, content: str):
    with anyio.CancelScope(shield=True):
        await anyio.to_thread.run_sync(
            _save_message_sync,
            models.ChatMessage(
                case_id=case_id,
                role=models.ChatRole.assistant,
                content=content,
            )
        )


@router.get("/chat/history")
async def chat_history(
    case_id: str,
    current_user: models.User = Depends(get_current_user),
):
    """Chat as the client should currently see it — messages older than
    `CHAT_HISTORY_MAX_AGE` are soft-hidden (filtered out here) but remain in
    Postgres untouched, so the app just looks like a fresh conversation."""
    res = await anyio.to_thread.run_sync(
        _get_case_and_history_sync, case_id, current_user.id, current_user.role
    )
    if not res:
        raise HTTPException(status_code=404, detail="Case not found")
    _, rows = res

    return [
        {
            "id": row.id,
            "role": row.role.value,
            "content": row.content,
            "in_scope": row.in_scope,
            "escalate": row.escalate,
            "created_at": row.created_at.isoformat(),
        }
        for row in rows
    ]


@router.post("/chat", response_model=schemas.ChatResponse)
async def chat(
    request: schemas.ChatRequest,
    current_user: models.User = Depends(get_current_user),
):
    case, patient_ctx, history, in_scope, escalate = await _process_chat_request(request, current_user)

    await _save_user_message(case.id, request.message, in_scope, escalate)

    if not in_scope:
        reply = (
            "I can't help with changing medication doses or schedules — that's a "
            "clinical decision. Please contact your clinician or use the emergency "
            "contact option for anything urgent."
        )
    else:
        chunks = []
        async for chunk in generate_recommendation_stream(
            request.message,
            case.surgery_type,
            patient_context=patient_ctx,
            history=history,
            locale=request.locale,
            case_id=case.id,
            patient_id=case.patient_id,
            clinician_id=case.clinician_id,
            requester_role=current_user.role.value,
        ):
            chunks.append(chunk)
        reply = "".join(chunks)

    await anyio.to_thread.run_sync(
        _save_message_sync,
        models.ChatMessage(
            case_id=case.id,
            role=models.ChatRole.assistant,
            content=reply,
        )
    )

    return schemas.ChatResponse(reply=reply, in_scope=in_scope, escalate=escalate)

@router.post("/chat/stream")
async def chat_stream(
    request: schemas.ChatRequest,
    current_user: models.User = Depends(get_current_user),
):
    case, patient_ctx, history, in_scope, escalate = await _process_chat_request(request, current_user)

    await _save_user_message(case.id, request.message, in_scope, escalate)

    if not in_scope:
        async def mock_stream():
            reply = (
                "I can't help with changing medication doses or schedules — that's a "
                "clinical decision. Please contact your clinician or use the emergency "
                "contact option for anything urgent."
            )
            try:
                yield reply
            finally:
                await _save_assistant_message_shielded(case.id, reply)
            return
        return StreamingResponse(mock_stream(), media_type="text/plain")

    async def stream_and_save():
        generator = generate_recommendation_stream(
            request.message,
            case.surgery_type,
            patient_context=patient_ctx,
            history=history,
            locale=request.locale,
            case_id=case.id,
            patient_id=case.patient_id,
            clinician_id=case.clinician_id,
            requester_role=current_user.role.value,
        )
        chunks = []
        try:
            async for chunk in generator:
                chunks.append(chunk)
                yield chunk
        finally:
            if chunks:
                await _save_assistant_message_shielded(case.id, "".join(chunks))

    return StreamingResponse(stream_and_save(), media_type="text/plain")


@router.get("/patients-summary")
async def patients_summary(
    locale: str | None = None,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):
    """Summarize the clinician's full patient roster using the LLM, with a
    'things to consider' section. Bypasses the RAG/embeddings pipeline
    entirely (chat completion only) since embeddings are unavailable."""
    cases = (
        db.query(models.Case)
        .filter(models.Case.clinician_id == current_user.id)
        .all()
    )

    if not cases:
        return {"summary": "You have no patients yet.", "patient_count": 0}

    lines = []
    for case in cases:
        patient = case.patient
        active_meds = [m.name for m in case.medications if m.discontinued_at is None]
        sorted_checkins = sorted(case.checkins, key=lambda c: c.created_at, reverse=True)
        latest_checkin = sorted_checkins[0] if sorted_checkins else None
        sorted_recs = sorted(case.recommendations, key=lambda r: r.created_at, reverse=True)
        latest_rec = sorted_recs[0] if sorted_recs else None

        lines.append(
            f"Patient: {patient.full_name}\n"
            f"Surgery: {case.surgery_type} (status: {case.status})\n"
            f"Active medications: {', '.join(active_meds) if active_meds else 'none'}\n"
            f"Latest check-in feeling: {latest_checkin.feeling.value if latest_checkin else 'no check-ins yet'}\n"
            f"Latest recommendation: {latest_rec.text if latest_rec else 'none'}"
        )

    patients_context = "\n\n---\n\n".join(lines)
    summary = await generate_patients_summary(patients_context, locale=locale, clinician_id=current_user.id)
    return {"summary": summary, "patient_count": len(cases)}
