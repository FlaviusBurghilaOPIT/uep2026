from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user
from app.providers.llm import get_llm_provider

router = APIRouter(prefix="/ai", tags=["ai"])

GUARDRAIL_PREAMBLE = (
    "You are a post-surgery recovery assistant. Answer only using the patient's "
    "prescribed medications and recovery recommendations below. You are strictly "
    "informational: never diagnose, never suggest changing a dose or schedule, and "
    "never recommend a new medication. If asked to do any of those, say you can't "
    "and suggest contacting the clinician or emergency contact."
)

OUT_OF_SCOPE_MARKERS = [
    "double dose",
    "extra dose",
    "stop taking",
    "change your dose",
    "increase your dose",
    "decrease your dose",
    "diagnose",
]


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


def _check_guardrail(user_message: str) -> tuple[bool, bool]:
    lowered = user_message.lower()
    flagged = any(marker in lowered for marker in OUT_OF_SCOPE_MARKERS)
    return (not flagged, flagged)


@router.post("/chat", response_model=schemas.ChatResponse)
async def chat(
    request: schemas.ChatRequest,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    case = db.query(models.Case).filter(models.Case.id == request.case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    in_scope, escalate = _check_guardrail(request.message)

    db.add(
        models.ChatMessage(
            case_id=case.id,
            role=models.ChatRole.user,
            content=request.message,
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
