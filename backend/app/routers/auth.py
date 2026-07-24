import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user
from app.security import create_access_token, verify_password
from app.services.email_service import EmailService

router = APIRouter(
    prefix="/auth",
    tags=["auth"],
)


@router.post("/login", response_model=schemas.TokenResponse)
@router.post("/dev-login", response_model=schemas.TokenResponse)
def login(login: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == login.email).first()

    if not user or not user.password_hash:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not verify_password(login.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})

    return {"access_token": token, "token_type": "bearer"}


@router.post("/verify-invite", response_model=schemas.VerifyInviteResponse)
def verify_invite(req: schemas.VerifyInviteRequest, db: Session = Depends(get_db)):
    user = (
        db.query(models.User)
        .filter(
            models.User.email == req.email,
            models.User.invite_code == req.invite_code,
            models.User.status == "pending_onboarding",
        )
        .first()
    )

    if not user:
        raise HTTPException(status_code=400, detail="Invalid email or invite code")

    return schemas.VerifyInviteResponse(
        email=user.email,
        full_name=user.full_name,
        invite_code=user.invite_code,
        status=user.status,
    )


@router.post("/complete-onboarding", response_model=schemas.TokenResponse)
def complete_onboarding(req: schemas.CompleteOnboardingRequest, db: Session = Depends(get_db)):
    user = (
        db.query(models.User)
        .filter(
            models.User.email == req.email,
            models.User.invite_code == req.invite_code,
            models.User.status == "pending_onboarding",
        )
        .first()
    )

    if not user:
        raise HTTPException(status_code=400, detail="Invalid email or invite code")

    user.date_of_birth = req.date_of_birth
    user.phone = req.phone
    user.status = "active"
    user.invite_code = None
    user.invite_code_expires_at = None

    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"access_token": token, "token_type": "bearer"}


@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user


@router.post("/patient/request-code", response_model=schemas.PatientRequestCodeResponse)
def request_patient_code(req: schemas.PatientRequestCodeRequest, db: Session = Depends(get_db)):
    user = (
        db.query(models.User)
        .filter(models.User.email == req.email, models.User.role == models.UserRole.patient)
        .first()
    )

    if user:
        code = f"{secrets.randbelow(900000) + 100000}"
        user.invite_code = code
        user.invite_code_expires_at = datetime.utcnow() + timedelta(minutes=15)
        db.commit()

        email_service = EmailService()
        email_service.send_patient_code(user.email, code)

    return schemas.PatientRequestCodeResponse()


@router.post("/patient/verify-code")
def verify_patient_code(req: schemas.PatientVerifyCodeRequest, db: Session = Depends(get_db)):
    user = (
        db.query(models.User)
        .filter(models.User.email == req.email, models.User.role == models.UserRole.patient)
        .first()
    )

    if (
        not user
        or not user.invite_code
        or user.invite_code != req.code
        or not user.invite_code_expires_at
        or user.invite_code_expires_at < datetime.utcnow()
    ):
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    if user.status == "pending_onboarding":
        return {
            "result": "onboarding",
            "email": user.email,
            "full_name": user.full_name,
        }

    user.invite_code = None
    user.invite_code_expires_at = None
    db.commit()

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"result": "authenticated", "access_token": token, "token_type": "bearer"}
