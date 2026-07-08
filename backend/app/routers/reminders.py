from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db


router = APIRouter(
    prefix="/reminders",
    tags=["reminders"]
)


@router.post("/", response_model=schemas.ReminderResponse)
def create_reminder(
    reminder: schemas.ReminderCreate,
    db: Session = Depends(get_db)
):

    db_reminder = models.ScheduledReminder(
        medication_id=reminder.medication_id,
        scheduled_time=reminder.scheduled_time
    )

    db.add(db_reminder)
    db.commit()
    db.refresh(db_reminder)

    return db_reminder

