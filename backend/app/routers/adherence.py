from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models
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
    db.commit()
    db.refresh(dose_log)

    return dose_log


@router.get("/patients/{patient_id}")
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

    return logs
