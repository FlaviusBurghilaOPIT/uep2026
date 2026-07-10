from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_db_for_user
from app.security import hash_password

router = APIRouter(
    prefix="/patients",
    tags=["patients"],
)


@router.post("/", response_model=schemas.UserResponse)
def create_patient(user: schemas.UserCreate, db: Session = Depends(get_db_for_user)):

    db_user = models.User(
        email=user.email,
        full_name=user.full_name,
        role=models.UserRole.patient,
        password_hash=hash_password(user.password),
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user


@router.get("/{patient_id}", response_model=schemas.UserResponse)
def get_patient(patient_id: str, db: Session = Depends(get_db_for_user)):

    patient = (
        db.query(models.User)
        .filter(models.User.id == patient_id, models.User.role == models.UserRole.patient)
        .first()
    )

    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    return patient


@router.get("/{patient_id}/case", response_model=schemas.CaseResponse)
def get_patient_case(patient_id: str, db: Session = Depends(get_db_for_user)):

    case = db.query(models.Case).filter(models.Case.patient_id == patient_id).first()

    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return case
