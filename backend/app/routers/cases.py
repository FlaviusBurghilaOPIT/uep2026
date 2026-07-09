from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app import models, schemas
from app.dependencies import get_current_user


router = APIRouter(
    prefix="/cases",
    tags=["cases"]
)


@router.post("/")
def create_case(
    case: schemas.CaseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    new_case = models.Case(
        clinician_id=current_user.id,
        patient_id=case.patient_id,
        surgery_type=case.surgery_type
    )

    db.add(new_case)
    db.commit()
    db.refresh(new_case)

    return new_case


@router.get("/", response_model=list[schemas.CaseResponse])
def list_cases(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    cases = db.query(models.Case).filter(
        models.Case.clinician_id == current_user.id
    ).all()

    return cases


@router.get("/{case_id}", response_model=schemas.CaseResponse)
def get_case(
    case_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    case = db.query(models.Case).filter(
        models.Case.id == case_id,
        models.Case.clinician_id == current_user.id
    ).first()

    if not case:
        raise HTTPException(
            status_code=404,
            detail="Case not found"
        )

    return case



@router.delete("/{case_id}")
def delete_case(
    case_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    case = db.query(models.Case).filter(
        models.Case.id == case_id,
        models.Case.clinician_id == current_user.id
    ).first()

    if not case:
        raise HTTPException(
            status_code=404,
            detail="Case not found"
        )

    db.delete(case)
    db.commit()

    return {
        "message": "Case deleted"
    }



@router.get("/{case_id}/medications", response_model=list[schemas.MedicationResponse])
def get_case_medications(
    case_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    medications = db.query(models.Medication).filter(
        models.Medication.case_id == case_id
    ).all()

    return medications

@router.post("/{case_id}/medications", response_model=schemas.MedicationResponse)
def create_case_medication(
    case_id: str,
    medication: schemas.MedicationCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    case = db.query(models.Case).filter(
        models.Case.id == case_id,
        models.Case.clinician_id == current_user.id
    ).first()

    if not case:
        raise HTTPException(
            status_code=404,
            detail="Case not found"
        )

    new_medication = models.Medication(
        case_id=case_id,
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
