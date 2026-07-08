from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import schemas, models
from app.database import get_db
from app.security import verify_password, create_access_token


router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)


@router.post("/dev-login", response_model=schemas.TokenResponse)
def dev_login(
    login: schemas.LoginRequest,
    db: Session = Depends(get_db)
):

    user = db.query(models.User).filter(
        models.User.email == login.email
    ).first()

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )

    if not verify_password(
        login.password,
        user.password_hash
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )

    token = create_access_token(
        {
            "sub": user.id,
            "role": user.role.value,
            "email": user.email
        }
    )

    return {
        "access_token": token,
        "token_type": "bearer"
    }

