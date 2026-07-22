import sys
from pathlib import Path

# Ensure backend root is in sys.path when script is executed directly
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from app import models
from app.database import SessionLocal, engine
from app.models import Base
from app.security import hash_password


def seed_database():
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
            print("Seeded clinician: clinician@example.com")
        else:
            print("Clinician clinician@example.com already exists.")

        # Check or create Patient
        patient = (
            db.query(models.User)
            .filter(models.User.email == "patient@example.com")
            .first()
        )
        if not patient:
            patient = models.User(
                email="patient@example.com",
                full_name="Sarah Mitchell",
                role=models.UserRole.patient,
                password_hash=hash_password("password123"),
                status="active",
                phone="+1 555-0199",
                date_of_birth="1988-04-12",
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
            print("Seeded patient: patient@example.com")
        else:
            print("Patient patient@example.com already exists.")

        # Check or create Case
        case = db.query(models.Case).filter(models.Case.patient_id == patient.id).first()
        if not case:
            case = models.Case(
                clinician_id=clinician.id,
                patient_id=patient.id,
                surgery_type="Total Knee Arthroplasty (TKA)",
                status="active",
                emergency_contact_name="Dr. Sarah Connor",
                emergency_contact_phone="+1 555-0122",
            )
            db.add(case)
            db.commit()
            db.refresh(case)
            print(f"Seeded case: {case.id}")

            # Seed Medications for this case
            meds = [
                models.Medication(
                    case_id=case.id,
                    name="Oxycodone",
                    dose="5mg",
                    schedule_text="Every 6 hours as needed",
                    duration="7 days",
                    notes="Take with food for pain management",
                ),
                models.Medication(
                    case_id=case.id,
                    name="Amoxicillin",
                    dose="500mg",
                    schedule_text="Every 8 hours",
                    duration="10 days",
                    notes="Complete full course of antibiotics",
                ),
                models.Medication(
                    case_id=case.id,
                    name="Ibuprofen",
                    dose="400mg",
                    schedule_text="Every 8 hours with meals",
                    duration="14 days",
                    notes="For swelling and inflammation",
                ),
            ]
            db.add_all(meds)

            # Seed Recommendations for this case
            recs = [
                models.Recommendation(
                    case_id=case.id,
                    text="Elevate leg above heart level for 30 minutes 3x daily",
                ),
                models.Recommendation(
                    case_id=case.id,
                    text="Apply ice pack to knee for 20 minutes after physical therapy exercises",
                ),
            ]
            db.add_all(recs)

            # Seed CheckIn for this case
            checkin = models.CheckIn(
                case_id=case.id,
                feeling=models.CheckInFeeling.ok,
            )
            db.add(checkin)

            db.commit()
            print("Seeded medications, recommendations, and check-ins for patient.")

    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
