from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models
from app.dependencies import get_current_user, get_db_for_user
from app.services.schedule_parser import (
    create_scheduled_reminders_for_medication,
    parse_duration_days,
)

router = APIRouter(
    prefix="/medications",
    tags=["medications"],
)


@router.delete("/{medication_id}")
def delete_medication(
    medication_id: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    medication = db.query(models.Medication).filter(models.Medication.id == medication_id).first()

    if not medication:
        raise HTTPException(status_code=404, detail="Medication not found")

    db.delete(medication)
    db.commit()

    return {"message": "Medication deleted"}
