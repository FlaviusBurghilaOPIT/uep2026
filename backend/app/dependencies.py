from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import text
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.database import get_db as _get_db
from app.providers.auth import get_auth_provider

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)
):

    token = credentials.credentials

    try:
        payload = await get_auth_provider().verify_token(token)
        user_id = payload.get("sub")

    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(models.User).filter(models.User.id == user_id).first()

    # Fallback to email lookup if user was re-seeded and user_id changed
    if not user and payload.get("email"):
        user = db.query(models.User).filter(models.User.email == payload.get("email")).first()

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return user


def get_db_for_user(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(_get_db),
):
    if db.bind.dialect.name == "postgresql":
        db.execute(
            text("SET LOCAL app.current_user_id = :uid"),
            {"uid": current_user.id},
        )
        db.execute(
            text('SET LOCAL "app.current_role" = :role'),
            {"role": current_user.role.value},
        )
    yield db


def require_clinician(current_user: models.User = Depends(get_current_user)) -> models.User:
    if current_user.role not in (models.UserRole.clinician, models.UserRole.admin):
        raise HTTPException(status_code=403, detail="Clinician access required")
    return current_user
