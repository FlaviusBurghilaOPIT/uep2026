from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user, require_clinician

router = APIRouter(
    prefix="/reminders",
    tags=["reminders"],
)


def _clinician_owns_medication(db: Session, medication_id: str, clinician_id: str) -> bool:
    return (
        db.query(models.Medication)
        .join(models.Case, models.Medication.case_id == models.Case.id)
        .filter(
            models.Medication.id == medication_id,
            models.Case.clinician_id == clinician_id,
        )
        .first()
        is not None
    )


# DEPRECATED — delete after mobile Today-screen migration
@router.post("/", response_model=schemas.ReminderResponse)
def create_reminder(
    reminder: schemas.ReminderCreate,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):

    medication = (
        db.query(models.Medication).filter(models.Medication.id == reminder.medication_id).first()
    )

    if not medication:
        raise HTTPException(status_code=404, detail="Medication not found")

    if not _clinician_owns_medication(db, reminder.medication_id, current_user.id):
        raise HTTPException(status_code=403, detail="Medication does not belong to your cases")

    db_reminder = models.ScheduledReminder(
        medication_id=reminder.medication_id, scheduled_time=reminder.scheduled_time
    )

    db.add(db_reminder)
    db.commit()
    db.refresh(db_reminder)

    return db_reminder


# DEPRECATED — delete after mobile Today-screen migration
@router.get("/", response_model=list[schemas.ReminderResponse])
def list_reminders(
    db: Session = Depends(get_db_for_user), current_user: models.User = Depends(get_current_user)
):

    query = db.query(models.ScheduledReminder).join(
        models.Medication, models.ScheduledReminder.medication_id == models.Medication.id
    ).join(models.Case, models.Medication.case_id == models.Case.id)

    if current_user.role == models.UserRole.patient:
        query = query.filter(models.Case.patient_id == current_user.id)
    else:
        query = query.filter(models.Case.clinician_id == current_user.id)

    return query.all()


# DEPRECATED — delete after mobile Today-screen migration
@router.patch("/{reminder_id}", response_model=schemas.ReminderResponse)
def update_reminder(
    reminder_id: str,
    status: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):

    reminder = (
        db.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.id == reminder_id)
        .first()
    )

    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    if not _clinician_owns_medication(db, reminder.medication_id, current_user.id):
        raise HTTPException(status_code=403, detail="Reminder does not belong to your cases")

    reminder.status = status

    db.commit()
    db.refresh(reminder)

    return reminder
