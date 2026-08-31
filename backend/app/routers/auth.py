import logging
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

logger = logging.getLogger("app.routers.auth")

router = APIRouter(
    prefix="/auth",
    tags=["auth"],
)


def _is_expired(expires_at: datetime | None) -> bool:
    if not expires_at:
        return False
    now = datetime.now(timezone.utc)
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    return expires_at < now


@router.post("/login", response_model=schemas.TokenResponse)
def login(login: schemas.LoginRequest, db: Session = Depends(get_db)):
    clean_email = login.email.strip().lower()
    user = db.query(models.User).filter(func.lower(models.User.email) == clean_email).first()

    if not user or not user.password_hash:
        logger.warning(f"[/auth/login] Login failed: user '{clean_email}' not found or has no password")
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not verify_password(login.password, user.password_hash):
        logger.warning(f"[/auth/login] Login failed: invalid password for '{clean_email}'")
        raise HTTPException(status_code=401, detail="Invalid credentials")

    logger.info(f"[/auth/login] Successful login for '{clean_email}' (role={user.role.value})")
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

    logger.info(f"[/auth/complete-onboarding] Attempt for email='{clean_email}', code='{clean_code}'")

    user = (
        db.query(models.User)
        .filter(
            func.lower(models.User.email) == clean_email,
            models.User.status == "pending_onboarding",
        )
        .first()
    )

    if not user:
        logger.warning(f"[/auth/complete-onboarding] No pending_onboarding user found for '{clean_email}'")
        raise HTTPException(status_code=400, detail="Invalid email or invite code")

    stored_code = str(user.invite_code).strip() if user.invite_code else None
    if not stored_code or not secrets.compare_digest(stored_code, clean_code) or _is_expired(user.invite_code_expires_at):
        logger.warning(
            f"[/auth/complete-onboarding] Invalid code for '{clean_email}': received='{clean_code}', stored='{stored_code}'"
        )
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
    logger.info(f"[/auth/complete-onboarding] Activated patient {user.id} ({user.email})")

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
    logger.info(f"[/auth/patient/request-code] Requesting code for email: '{clean_email}'")
    user = (
        db.query(models.User)
        .filter(func.lower(models.User.email) == clean_email, models.User.role == models.UserRole.patient)
        .first()
    )

    if user:
        # If user is in pending_onboarding and already has a valid invite code from clinician intake, preserve it
        if user.status == "pending_onboarding" and user.invite_code and not _is_expired(user.invite_code_expires_at):
            code = str(user.invite_code).strip()
            logger.info(f"[/auth/patient/request-code] Preserved active onboarding code '{code}' for '{user.email}'")
        else:
            code = f"{secrets.randbelow(900000) + 100000}"
            user.invite_code = code
            user.invite_code_expires_at = datetime.now(timezone.utc) + timedelta(hours=24)
            db.commit()
            logger.info(f"[/auth/patient/request-code] Generated fresh code '{code}' for '{user.email}'")

        email_service = EmailService()
        email_service.send_patient_code(user.email, code)
    else:
        logger.warning(f"[/auth/patient/request-code] Patient not found for email: '{clean_email}'")

    return schemas.PatientRequestCodeResponse()


@router.post("/patient/verify-code")
def verify_patient_code(req: schemas.PatientVerifyCodeRequest, db: Session = Depends(get_db)):
    clean_email = req.email.strip().lower()
    clean_code = str(req.code).strip()

    logger.info(f"[/auth/patient/verify-code] Verify attempt: email='{clean_email}', code='{clean_code}'")

    user = (
        db.query(models.User)
        .filter(func.lower(models.User.email) == clean_email, models.User.role == models.UserRole.patient)
        .first()
    )

    if not user:
        logger.warning(f"[/auth/patient/verify-code] Patient not found for email: '{clean_email}'")
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    stored_code = str(user.invite_code).strip() if user.invite_code else None
    logger.info(
        f"[/auth/patient/verify-code] Found user {user.id} ({user.email}), status='{user.status}', "
        f"stored_code='{stored_code}', expires_at={user.invite_code_expires_at}"
    )

    if not stored_code:
        logger.warning(f"[/auth/patient/verify-code] User '{user.email}' has no invite_code set")
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    if _is_expired(user.invite_code_expires_at):
        logger.warning(
            f"[/auth/patient/verify-code] Code expired for '{user.email}': expires_at={user.invite_code_expires_at}, now={datetime.now(timezone.utc)}"
        )
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    if not secrets.compare_digest(stored_code, clean_code):
        logger.warning(
            f"[/auth/patient/verify-code] Code mismatch for '{user.email}': received='{clean_code}', stored='{stored_code}'"
        )
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    logger.info(f"[/auth/patient/verify-code] Code successfully verified for '{user.email}' (status='{user.status}')")

    if user.status == "pending_onboarding":
        case = db.query(models.Case).filter(models.Case.patient_id == user.id).first()
        physician_name = None
        if case and case.clinician:
            physician_name = case.clinician.full_name
        return {
            "result": "onboarding",
            "email": user.email,
            "full_name": user.full_name,
            "date_of_birth": user.date_of_birth,
            "clinic_name": "St. Jude Recovery Clinic",
            "physician_name": physician_name or "Dr. Miller",
        }

    user.invite_code = None
    user.invite_code_expires_at = None
    db.commit()

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"result": "authenticated", "access_token": token, "token_type": "bearer"}
