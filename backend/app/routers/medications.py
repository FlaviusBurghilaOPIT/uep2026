from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models
from app.dependencies import get_current_user, get_db_for_user

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
    """Soft-delete (spec E4): sets `discontinued_at` instead of deleting the
    row so adherence history (reminders, dose logs, events) is preserved."""

    medication = (
        db.query(models.Medication).filter(models.Medication.id == medication_id).first()
    )

    if not medication:
        raise HTTPException(status_code=404, detail="Medication not found")

    case = db.query(models.Case).filter(models.Case.id == medication.case_id).first()
    is_owner_clinician = (
        current_user.role in (models.UserRole.clinician, models.UserRole.admin)
        and case is not None
        and case.clinician_id == current_user.id
    )
    if not is_owner_clinician:
        raise HTTPException(
            status_code=403, detail="Not authorized to discontinue this medication"
        )

    if medication.discontinued_at is None:
        medication.discontinued_at = datetime.utcnow()
        db.commit()

    return {"message": "Medication discontinued"}
