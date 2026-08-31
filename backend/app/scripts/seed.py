from sqlalchemy.orm import Session

from app import models
from app.security import hash_password

SEED_USERS = [
    ("admin@remotecarepro.dev", "Seed Admin", models.UserRole.admin, "admin1234"),
    ("clinician@remotecarepro.dev", "Seed Clinician", models.UserRole.clinician, "clinician1234"),
    ("patient@remotecarepro.dev", "Seed Patient", models.UserRole.patient, "patient1234"),
]


def seed(db: Session) -> dict:
    result = {}
    for email, full_name, role, password in SEED_USERS:
        existing = db.query(models.User).filter(models.User.email == email).first()
        if existing:
            result[role.value] = existing
            continue

        user = models.User(
            email=email,
            full_name=full_name,
            role=role,
            password_hash=hash_password(password),
            invite_code="424242" if role == models.UserRole.patient else None,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        result[role.value] = user

    return result


if __name__ == "__main__":
    from app.database import SessionLocal

    db = SessionLocal()
    try:
        created = seed(db)
        print("Seeded users (email / password):")
        for email, _, role, password in SEED_USERS:
            print(f"  {role.value}: {email} / {password}")
    finally:
        db.close()
