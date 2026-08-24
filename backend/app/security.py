import os
from datetime import datetime, timedelta

from jose import jwt
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


ENV = os.getenv("ENV", os.getenv("ENVIRONMENT", "development")).lower()
SECRET_KEY = os.getenv("JWT_SECRET", "dev-secret-change-in-prod")

if ENV in ("production", "prod") and (not os.getenv("JWT_SECRET") or SECRET_KEY == "dev-secret-change-in-prod"):
    raise RuntimeError("CRITICAL: JWT_SECRET must be set to a secure, non-default value in production!")

ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict):
    to_encode = data.copy()

    expire = datetime.utcnow() + timedelta(minutes=60)

    to_encode.update({"exp": expire})

    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
