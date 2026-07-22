import secrets

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user, require_clinician
from app.security import hash_password

router = APIRouter(
    prefix="/patients",
    tags=["patients"],
)


@router.post("/invite", response_model=schemas.PatientInviteResponse)
def invite_patient(
    req: schemas.PatientInviteRequest,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):
    existing_user = db.query(models.User).filter(models.User.email == req.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User with this email already exists")

    invite_code = f"{secrets.randbelow(900000) + 100000}"

    patient = models.User(
        email=req.email,
        full_name=req.full_name,
        role=models.UserRole.patient,
        status="pending_onboarding",
        invite_code=invite_code,
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)

    case = models.Case(
        clinician_id=current_user.id,
        patient_id=patient.id,
        surgery_type=req.surgery_type,
        emergency_contact_name=current_user.full_name,
        emergency_contact_phone=req.emergency_contact_phone,
        status="active",
    )
    db.add(case)
    db.commit()

    return schemas.PatientInviteResponse(
        patient_id=patient.id,
        invite_code=invite_code,
        email=patient.email,
        full_name=patient.full_name,
    )


@router.get("/", response_model=list[schemas.UserResponse])
def list_patients(
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    patients = db.query(models.User).filter(models.User.role == models.UserRole.patient).all()
    return patients


@router.post("/", response_model=schemas.UserResponse)
def create_patient(user: schemas.UserCreate, db: Session = Depends(get_db_for_user)):

    db_user = models.User(
        email=user.email,
        full_name=user.full_name,
        role=models.UserRole.patient,
        password_hash=hash_password(user.password),
        status="active",
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
