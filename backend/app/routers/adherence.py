from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user

router = APIRouter(
    prefix="/adherence",
    tags=["adherence"],
)


@router.post("/log")
def log_dose(
    scheduled_reminder_id: str,
    status: models.DoseStatus,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    reminder = (
        db.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.id == scheduled_reminder_id)
        .first()
    )

    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    dose_log = models.DoseLog(
        scheduled_reminder_id=scheduled_reminder_id, status=status, logged_at=datetime.utcnow()
    )

    db.add(dose_log)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = (
            db.query(models.DoseLog)
            .filter(models.DoseLog.scheduled_reminder_id == scheduled_reminder_id)
            .first()
        )
        raise HTTPException(
            status_code=409,
            detail={
                "message": "Dose already logged for this reminder",
                "id": existing.id,
                "scheduled_reminder_id": existing.scheduled_reminder_id,
                "status": existing.status,
                "logged_at": existing.logged_at.isoformat() if existing.logged_at else None,
            },
        )

    db.refresh(dose_log)

    return dose_log


@router.get("/patients/{patient_id}", response_model=list[schemas.DoseLogDetailResponse])
def get_patient_adherence(
    patient_id: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    logs = (
        db.query(models.DoseLog)
        .join(
            models.ScheduledReminder,
            models.DoseLog.scheduled_reminder_id == models.ScheduledReminder.id,
        )
        .join(models.Medication, models.ScheduledReminder.medication_id == models.Medication.id)
        .join(models.Case, models.Medication.case_id == models.Case.id)
        .filter(models.Case.patient_id == patient_id)
        .all()
    )

    return [
        schemas.DoseLogDetailResponse(
            id=log.id,
            scheduled_reminder_id=log.scheduled_reminder_id,
            status=log.status.value if hasattr(log.status, "value") else str(log.status),
            logged_at=log.logged_at,
            medication_name=(
                log.scheduled_reminder.medication.name
                if log.scheduled_reminder and log.scheduled_reminder.medication
                else None
            ),
            scheduled_time=(
                log.scheduled_reminder.scheduled_time if log.scheduled_reminder else None
            ),
        )
        for log in logs
    ]


@router.get("/patients/{patient_id}/export")
def export_patient_telemetry_adherence(
    patient_id: str,
    format: str = "csv",
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    from app.routers.patients import export_patient_telemetry

    return export_patient_telemetry(
        patient_id=patient_id, format=format, db=db, current_user=current_user
    )

