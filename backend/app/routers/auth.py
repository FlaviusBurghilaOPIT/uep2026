import os
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user
from app.security import create_access_token, hash_password, verify_password
from app.services.email_service import EmailService

router = APIRouter(
    prefix="/auth",
    tags=["auth"],
)


def _is_expired(expires_at: datetime | None) -> bool:
    if not expires_at:
        return True
    now = datetime.now(timezone.utc)
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    return expires_at < now


@router.post("/login", response_model=schemas.TokenResponse)
def login(login: schemas.LoginRequest, db: Session = Depends(get_db)):
    clean_email = login.email.strip().lower()
    user = db.query(models.User).filter(func.lower(models.User.email) == clean_email).first()

    if not user or not user.password_hash:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not verify_password(login.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})

    return {"access_token": token, "token_type": "bearer"}


@router.post("/verify-invite", response_model=schemas.VerifyInviteResponse)
def verify_invite(req: schemas.VerifyInviteRequest, db: Session = Depends(get_db)):
    clean_email = req.email.strip().lower()
    clean_code = str(req.invite_code).strip()

    user = (
        db.query(models.User)
        .filter(
            func.lower(models.User.email) == clean_email,
            models.User.invite_code == clean_code,
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
    clean_email = req.email.strip().lower()
    clean_code = str(req.invite_code).strip()

    user = (
        db.query(models.User)
        .filter(
            func.lower(models.User.email) == clean_email,
            models.User.invite_code == clean_code,
            models.User.status == "pending_onboarding",
        )
        .first()
    )

    if not user or _is_expired(user.invite_code_expires_at):
        raise HTTPException(status_code=400, detail="Invalid email or invite code")

    if req.date_of_birth is not None:
        user.date_of_birth = req.date_of_birth
    if req.full_name is not None:
        user.full_name = req.full_name
    user.phone = req.phone
    if req.password is not None:
        user.password_hash = hash_password(req.password)
    user.status = "active"
    user.invite_code = None
    user.invite_code_expires_at = None

    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"access_token": token, "token_type": "bearer"}


@router.post("/change-password", response_model=schemas.ChangePasswordResponse)
def change_password(
    req: schemas.ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if current_user.password_hash:
        if not req.current_password or not verify_password(
            req.current_password, current_user.password_hash
        ):
            raise HTTPException(status_code=400, detail="Current password is incorrect")

    current_user.password_hash = hash_password(req.new_password)
    db.commit()

    return schemas.ChangePasswordResponse()


@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=schemas.UserResponse)
def update_me(
    req: schemas.UserUpdateRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if req.full_name is not None:
        current_user.full_name = req.full_name
    if req.phone is not None:
        current_user.phone = req.phone
    if req.date_of_birth is not None:
        current_user.date_of_birth = req.date_of_birth

    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/patient/request-code", response_model=schemas.PatientRequestCodeResponse)
def request_patient_code(req: schemas.PatientRequestCodeRequest, db: Session = Depends(get_db)):
    clean_email = req.email.strip().lower()
    user = (
        db.query(models.User)
        .filter(func.lower(models.User.email) == clean_email, models.User.role == models.UserRole.patient)
        .first()
    )

    if user:
        code = f"{secrets.randbelow(900000) + 100000}"
        user.invite_code = code
        user.invite_code_expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
        db.commit()

        email_service = EmailService()
        email_service.send_patient_code(user.email, code)

    return schemas.PatientRequestCodeResponse()


@router.post("/patient/verify-code")
def verify_patient_code(req: schemas.PatientVerifyCodeRequest, db: Session = Depends(get_db)):
    clean_email = req.email.strip().lower()
    clean_code = str(req.code).strip()

    user = (
        db.query(models.User)
        .filter(func.lower(models.User.email) == clean_email, models.User.role == models.UserRole.patient)
        .first()
    )

    valid_stored_code = False
    if user and user.invite_code:
        valid_stored_code = (
            secrets.compare_digest(str(user.invite_code).strip(), clean_code)
            and not _is_expired(user.invite_code_expires_at)
        )

    if not user or not valid_stored_code:
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    if user.status == "pending_onboarding":
        return {
            "result": "onboarding",
            "email": user.email,
            "full_name": user.full_name,
            "date_of_birth": user.date_of_birth,
        }

    user.invite_code = None
    user.invite_code_expires_at = None
    db.commit()

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"result": "authenticated", "access_token": token, "token_type": "bearer"}
