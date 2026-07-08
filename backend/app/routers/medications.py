from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app import models, schemas
from app.dependencies import get_current_user


router = APIRouter(
    prefix="/medications",
    tags=["medications"]
)


@router.post("/")
def create_medication(
    medication: schemas.MedicationCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    new_medication = models.Medication(
        case_id=medication.case_id,
        name=medication.name,
        dose=medication.dose,
        schedule_text=medication.schedule_text,
        duration=medication.duration,
        notes=medication.notes
    )

    db.add(new_medication)
    db.commit()
    db.refresh(new_medication)

    return new_medication


@router.delete("/{medication_id}")
def delete_medication(
    medication_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    medication = db.query(models.Medication).filter(
        models.Medication.id == medication_id
    ).first()

    if not medication:
        raise HTTPException(
            status_code=404,
            detail="Medication not found"
        )

    db.delete(medication)
    db.commit()

    return {
        "message": "Medication deleted"
    }
