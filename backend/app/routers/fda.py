import json
import logging
import os
from contextlib import contextmanager
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException

try:
    from openinference.instrumentation import using_attributes
except ImportError:
    @contextmanager
    def using_attributes(**kwargs):
        yield

from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user, require_clinician
from app.providers.fda import get_fda_provider
from openai import AsyncOpenAI

router = APIRouter(prefix="/fda", tags=["fda"])
logger = logging.getLogger(__name__)


def _raw_warnings_text(raw: dict) -> str:
    """Best-effort plain-text fallback when the LLM summary is unavailable."""
    warnings: list[str] = []
    if isinstance(raw, dict):
        results = raw.get("results")
        if isinstance(results, list) and results and isinstance(results[0], dict):
            first = results[0].get("warnings")
            if isinstance(first, list):
                warnings = [str(w) for w in first]
        if not warnings and isinstance(raw.get("warnings"), list):
            warnings = [str(w) for w in raw["warnings"]]
    if warnings:
        return "\n".join(f"- {w}" for w in warnings[:5])
    return "Safety summary temporarily unavailable. Please consult the openFDA label directly."

FDA_SUMMARY_SYSTEM_PROMPT = (
    "You are a patient-facing drug safety summarizer. Given raw openFDA label data, "
    "produce a short, plain-language summary of key warnings and safety information. "
    "You are strictly informational: never advise changing a dose, never diagnose. "
    "If the data is sparse or missing, say so plainly rather than guessing."
)

client_async = AsyncOpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY") or "dummy-openrouter-key",
    base_url="https://openrouter.ai/api/v1"
)

@router.get("/drug/{name}", response_model=schemas.FDADrugInfoResponse)
async def get_drug_info(name: str, current_user: models.User = Depends(get_current_user)):
    provider = get_fda_provider()

    try:
        raw = await provider.get_drug_info(name)
    except Exception as exc:
        # openFDA unreachable/slow — degrade gracefully rather than returning a 500.
        logger.warning("openFDA lookup network error for drug=%s: %s", name, exc)
        return schemas.FDADrugInfoResponse(
            drug_name=name,
            summary="Could not reach openFDA right now. Please try again shortly.",
            source=f"{provider.source} (unavailable)",
        )

    if raw.get("not_found"):
        return schemas.FDADrugInfoResponse(
            drug_name=name,
            summary=f"No official openFDA drug label found for '{name}'. Please check medication spelling.",
            source=f"{provider.source} (not found)",
        )

    try:
        with using_attributes(metadata={"endpoint": "fda.summarize", "drug_name": name}):
            response = await client_async.chat.completions.create(
                model=os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3-8b-instruct"),
                messages=[
                    {"role": "system", "content": FDA_SUMMARY_SYSTEM_PROMPT},
                    {"role": "user", "content": json.dumps(raw)[:4000]}
                ],
                timeout=float(os.getenv("OPENROUTER_TIMEOUT", "20")),
            )
        summary = response.choices[0].message.content
        return schemas.FDADrugInfoResponse(drug_name=name, summary=summary, source=provider.source)
    except Exception:
        # Missing/invalid LLM key or a provider error — return the raw warnings
        # unsummarized instead of failing the whole request.
        logger.warning("LLM summary failed for drug=%s", name, exc_info=True)
        return schemas.FDADrugInfoResponse(
            drug_name=name,
            summary=_raw_warnings_text(raw),
            source=f"{provider.source} (unsummarized)",
        )


@router.get("/warnings", response_model=list[schemas.FDAWarningResponse])
def list_pending_warnings(
    db: Session = Depends(get_db), current_user: models.User = Depends(require_clinician)
):
    warnings = (
        db.query(models.FDAWarning)
        .filter(models.FDAWarning.status == models.FDAWarningStatus.pending)
        .all()
    )

    return warnings


@router.post("/warnings/{warning_id}/approve", response_model=schemas.FDAWarningResponse)
def approve_warning(
    warning_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_clinician),
):
    warning = db.query(models.FDAWarning).filter(models.FDAWarning.id == warning_id).first()

    if not warning:
        raise HTTPException(status_code=404, detail="Warning not found")

    warning.status = models.FDAWarningStatus.approved
    warning.reviewed_by = current_user.id
    warning.reviewed_at = datetime.utcnow()

    affected_cases = (
        db.query(models.Case)
        .join(models.Medication, models.Medication.case_id == models.Case.id)
        .filter(models.Case.status == "active", models.Medication.name.ilike(warning.drug_name))
        .distinct()
        .all()
    )

    for case in affected_cases:
        db.add(models.CaseFDAWarning(case_id=case.id, fda_warning_id=warning.id))

    db.commit()
    db.refresh(warning)

    return warning


@router.post("/warnings/{warning_id}/dismiss", response_model=schemas.FDAWarningResponse)
def dismiss_warning(
    warning_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_clinician),
):
    warning = db.query(models.FDAWarning).filter(models.FDAWarning.id == warning_id).first()

    if not warning:
        raise HTTPException(status_code=404, detail="Warning not found")

    warning.status = models.FDAWarningStatus.dismissed
    warning.reviewed_by = current_user.id
    warning.reviewed_at = datetime.utcnow()

    db.commit()
    db.refresh(warning)

    return warning


@router.post("/warnings/refresh", response_model=list[schemas.FDAWarningResponse])
async def refresh_warnings(
    db: Session = Depends(get_db), current_user: models.User = Depends(require_clinician)
):
    provider = get_fda_provider()
    distinct_names = [row[0] for row in db.query(models.Medication.name).distinct().all()]

    created = []
    for name in distinct_names:
        info = await provider.get_drug_info(name)
        summary = str(info.get("warnings", info))[:2000]

        existing = (
            db.query(models.FDAWarning)
            .filter(
                models.FDAWarning.drug_name.ilike(name),
                models.FDAWarning.summary == summary,
            )
            .first()
        )
        if existing:
            continue

        warning = models.FDAWarning(
            drug_name=name,
            summary=summary,
            severity="unknown",
            source_payload=str(info)[:4000],
        )
        db.add(warning)
        created.append(warning)

    db.commit()
    for w in created:
        db.refresh(w)

    return created
