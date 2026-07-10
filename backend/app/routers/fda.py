from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user, require_clinician
from app.providers.fda import get_fda_provider

router = APIRouter(prefix="/fda", tags=["fda"])


@router.get("/drug/{name}")
async def get_drug_info(name: str, current_user: models.User = Depends(get_current_user)):
    provider = get_fda_provider()
    return await provider.get_drug_info(name)


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
