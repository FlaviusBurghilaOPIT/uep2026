from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter(
    prefix="/reminders",
    tags=["reminders"]
)


@router.post("/", response_model=schemas.ReminderResponse)
def create_reminder(
    reminder: schemas.ReminderCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    db_reminder = models.ScheduledReminder(
        medication_id=reminder.medication_id,
        scheduled_time=reminder.scheduled_time
    )

    db.add(db_reminder)
    db.commit()
    db.refresh(db_reminder)

    return db_reminder

@router.get("/", response_model=list[schemas.ReminderResponse])
def list_reminders(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    reminders = db.query(models.ScheduledReminder).all()

    return reminders


@router.patch("/{reminder_id}", response_model=schemas.ReminderResponse)
def update_reminder(
    reminder_id: str,
    status: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    reminder = db.query(models.ScheduledReminder).filter(
        models.ScheduledReminder.id == reminder_id
    ).first()

    if not reminder:
        raise HTTPException(
            status_code=404,
            detail="Reminder not found"
        )

    reminder.status = status

    db.commit()
    db.refresh(reminder)

    return reminder
