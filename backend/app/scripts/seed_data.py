import sys
from datetime import datetime, timedelta
from pathlib import Path

# Ensure backend root is in sys.path when script is executed directly
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from sqlalchemy import text

from app import models
from app.database import SessionLocal, engine
from app.models import Base
from app.security import hash_password

DEMO_PATIENT_CODE = "424242"


def seed_database():
    # Ensure pgvector extension exists before table creation
    try:
        with engine.connect() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            conn.commit()
    except Exception as e:
        print(f"Note: pgvector extension initialization note: {e}")

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Check or create Clinician
        clinician = (
            db.query(models.User)
            .filter(models.User.email == "clinician@example.com")
            .first()
        )
        if not clinician:
            clinician = models.User(
                email="clinician@example.com",
                full_name="Dr. Sarah Connor",
                role=models.UserRole.clinician,
                password_hash=hash_password("password123"),
                status="active",
            )
            db.add(clinician)
            db.commit()
            db.refresh(clinician)
            print("Seeded clinician: clinician@example.com (password: password123)")
        else:
            print("Clinician clinician@example.com already exists.")

    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
