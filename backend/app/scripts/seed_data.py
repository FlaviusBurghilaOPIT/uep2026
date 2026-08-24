"""
RemoteCare Pro — Demo Database Seed Script
Supports 2 test simulations for live demos and grading:

1. Clinician Only Mode (--mode clinician-only / --clinician-only):
   Seeds ONLY the clinician account (Dr. Sarah Connor). The database has zero patients,
   cases, or prescriptions, allowing you to demonstrate the full end-to-end authoring
   flow (creating a patient, creating a case, and prescribing medications) live on camera.

2. Full Simulation Mode (--mode full / --full / default):
   Seeds the complete platform state including the clinician, main demo patient
   (Sarah Mitchell with Total Knee Arthroplasty, Ibuprofen/Amoxicillin BID, today's pending
   doses, and recommendations), plus 4 background triage roster patients (Amber/Green).

Usage:
    # Mode 1: Clinician Only (for live authoring demo)
    python app/scripts/seed_data.py --mode clinician-only --reset

    # Mode 2: Full Simulation (for complete end-to-end demo)
    python app/scripts/seed_data.py --mode full --reset
"""

import sys
import argparse
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path

# Ensure backend root is in sys.path when script is executed directly
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from sqlalchemy import text
from sqlalchemy.orm import Session

from app import models
from app.database import SessionLocal, engine
from app.models import Base
from app.security import hash_password

DEMO_PATIENT_CODE = "424242"
DEFAULT_PASSWORD = "password123"


def get_utc_today() -> date:
    return datetime.now(timezone.utc).date()


def clean_demo_data(db: Session, keep_clinician: bool = False):
    """Wipes all demo records (cases, medications, logs, checkins, chat, patients)."""
    demo_emails = [
        "patient@example.com",
        "john.davies@example.com",
        "emma.wilson@example.com",
        "maria.garcia@example.com",
        "robert.chen@example.com",
    ]
    if not keep_clinician:
        demo_emails.append("clinician@example.com")

    users = db.query(models.User).filter(models.User.email.in_(demo_emails)).all()
    for u in users:
        cases = db.query(models.Case).filter(
            (models.Case.clinician_id == u.id) | (models.Case.patient_id == u.id)
        ).all()
        for c in cases:
            db.query(models.ChatMessage).filter(models.ChatMessage.case_id == c.id).delete()
            db.query(models.CheckIn).filter(models.CheckIn.case_id == c.id).delete()
            db.query(models.Recommendation).filter(models.Recommendation.case_id == c.id).delete()
            meds = db.query(models.Medication).filter(models.Medication.case_id == c.id).all()
            for m in meds:
                reminders = db.query(models.ScheduledReminder).filter(models.ScheduledReminder.medication_id == m.id).all()
                for r in reminders:
                    db.query(models.DoseLog).filter(models.DoseLog.scheduled_reminder_id == r.id).delete()
                    db.query(models.ScheduledReminder).filter(models.ScheduledReminder.id == r.id).delete()
                db.query(models.Medication).filter(models.Medication.id == m.id).delete()
            db.query(models.Case).filter(models.Case.id == c.id).delete()
        if not (keep_clinician and u.email == "clinician@example.com"):
            db.query(models.User).filter(models.User.id == u.id).delete()
    db.commit()


def seed_guidelines_if_empty(db: Session):
    """Loads clinical guideline chunks into the vector database for RAG assistant."""
    try:
        from app.services.seed_guidelines import GUIDELINES, Embedding
        from app.services.rag import get_embedding

        existing_emb = db.query(Embedding).count()
        if existing_emb == 0:
            print(f"Seeding {len(GUIDELINES)} clinical guidelines into vector database...")
            for g in GUIDELINES:
                try:
                    emb_vec = get_embedding(g["content"])
                except Exception:
                    emb_vec = [0.0] * 1536
                emb = Embedding(
                    content=g["content"],
                    source=g["source"],
                    source_type=g["source_type"],
                    surgery_type=g["surgery_type"],
                    embedding=emb_vec,
                )
                db.add(emb)
            db.commit()
            print("Seeded clinical guideline embeddings for AI Assistant.")
    except Exception as emb_err:
        print(f"Note: Vector guidelines initialization note: {emb_err}")


def seed_database(mode: str = "full", reset: bool = False):
    # Ensure pgvector extension exists before table creation
    try:
        with engine.connect() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            conn.commit()
    except Exception as e:
        print(f"Note: pgvector extension initialization note: {e}")

    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()

    try:
        today = get_utc_today()

        if reset:
            print(f"--- Resetting existing demo data (Mode: {mode}) ---")
            clean_demo_data(db, keep_clinician=False)
            print("Cleaned existing demo user data.")
        elif mode == "clinician-only":
            # In clinician-only mode without full reset, ensure other demo patients/cases are removed
            clean_demo_data(db, keep_clinician=True)

        # =========================================================================
        # 1. Clinician: Dr. Sarah Connor
        # =========================================================================
        clinician = db.query(models.User).filter(models.User.email == "clinician@example.com").first()
        if not clinician:
            clinician = models.User(
                email="clinician@example.com",
                full_name="Dr. Sarah Connor",
                role=models.UserRole.clinician,
                password_hash=hash_password(DEFAULT_PASSWORD),
                status="active",
                phone="+1 555-0100",
            )
            db.add(clinician)
            db.commit()
            db.refresh(clinician)
            print("Created clinician: clinician@example.com (password: password123)")
        else:
            clinician.password_hash = hash_password(DEFAULT_PASSWORD)
            clinician.status = "active"
            db.commit()
            print("Verified clinician: clinician@example.com")

        # Load guidelines for AI assistant
        seed_guidelines_if_empty(db)

        # =========================================================================
        # MODE 1: Clinician Only Mode Exit
        # =========================================================================
        if mode == "clinician-only":
            print("\n" + "=" * 75)
            print("  RemoteCare Pro — SIMULATION 1: CLINICIAN-ONLY SEED COMPLETE")
            print("=" * 75)
            print("  Ready for live authoring demo! No patients or cases currently exist.")
            print("  Log in to the Clinician Web Portal to create a patient and surgical case live.")
            print("\n  CLINICIAN CREDENTIALS (Web Portal):")
            print("    • URL:      http://localhost:3000/login (or http://localhost:5173/login)")
            print("    • Email:    clinician@example.com")
            print("    • Password: password123")
            print("=" * 75 + "\n")
            return

        # =========================================================================
        # MODE 2: Full Simulation Mode (Patient + Case + Roster)
        # =========================================================================

        # Main Demo Patient: Sarah Mitchell
        patient = db.query(models.User).filter(models.User.email == "patient@example.com").first()
        if not patient:
            patient = models.User(
                email="patient@example.com",
                full_name="Sarah Mitchell",
                role=models.UserRole.patient,
                status="active",
                phone="+1 555-0199",
                date_of_birth="1988-04-12",
                password_hash=hash_password(DEFAULT_PASSWORD),
                invite_code=DEMO_PATIENT_CODE,
                invite_code_expires_at=datetime.now(timezone.utc) + timedelta(days=365),
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
            print(f"Created demo patient: patient@example.com (OTP: {DEMO_PATIENT_CODE})")
        else:
            patient.invite_code = DEMO_PATIENT_CODE
            patient.invite_code_expires_at = datetime.now(timezone.utc) + timedelta(days=365)
            patient.password_hash = hash_password(DEFAULT_PASSWORD)
            db.commit()
            print(f"Refreshed demo patient: patient@example.com (OTP: {DEMO_PATIENT_CODE})")

        # Case for Sarah Mitchell
        case = db.query(models.Case).filter(models.Case.patient_id == patient.id).first()
        if not case:
            case = models.Case(
                clinician_id=clinician.id,
                patient_id=patient.id,
                surgery_type="Total Knee Arthroplasty (TKA)",
                surgery_date=today.isoformat(),
                status="active",
                emergency_contact_name="Dr. Sarah Connor",
                emergency_contact_phone="+1 555-0122",
            )
            db.add(case)
            db.commit()
            db.refresh(case)
            print(f"Created surgical case for Sarah Mitchell: {case.id}")
        else:
            case.surgery_type = "Total Knee Arthroplasty (TKA)"
            case.emergency_contact_name = "Dr. Sarah Connor"
            case.emergency_contact_phone = "+1 555-0122"
            db.commit()

        # Seed Medications for Sarah Mitchell
        existing_meds = db.query(models.Medication).filter(models.Medication.case_id == case.id).all()
        if not existing_meds:
            med_ibuprofen = models.Medication(
                case_id=case.id,
                name="Ibuprofen",
                dose="400mg",
                schedule_text="BID",
                duration="14 days",
                notes="Take with meals for swelling and pain management",
            )
            med_amoxicillin = models.Medication(
                case_id=case.id,
                name="Amoxicillin",
                dose="500mg",
                schedule_text="BID",
                duration="10 days",
                notes="Take with full glass of water every 12 hours. Complete entire course.",
            )
            med_oxycodone = models.Medication(
                case_id=case.id,
                name="Oxycodone",
                dose="5mg",
                schedule_text="PRN",
                duration="5 days",
                notes="For severe breakthrough pain only. Do not exceed prescribed frequency.",
            )
            db.add_all([med_ibuprofen, med_amoxicillin, med_oxycodone])
            db.commit()
            db.refresh(med_ibuprofen)
            db.refresh(med_amoxicillin)
            db.refresh(med_oxycodone)
            print("Seeded medications (Ibuprofen 400mg BID, Amoxicillin 500mg BID, Oxycodone 5mg PRN).")
        else:
            med_ibuprofen = next((m for m in existing_meds if "ibuprofen" in m.name.lower()), existing_meds[0])
            med_amoxicillin = next((m for m in existing_meds if "amoxicillin" in m.name.lower()), existing_meds[1] if len(existing_meds) > 1 else existing_meds[0])

        # Materialize Today's scheduled reminder slots for Sarah Mitchell (08:00 AM & 20:00 PM)
        for med in [med_ibuprofen, med_amoxicillin]:
            for reminder_time in [time(8, 0), time(20, 0)]:
                sched_dt = datetime.combine(today, reminder_time)
                reminder = db.query(models.ScheduledReminder).filter(
                    models.ScheduledReminder.medication_id == med.id,
                    models.ScheduledReminder.scheduled_time == sched_dt,
                ).first()
                if not reminder:
                    reminder = models.ScheduledReminder(
                        medication_id=med.id,
                        scheduled_time=sched_dt,
                        status="pending",
                    )
                    db.add(reminder)
                    db.commit()
                elif reset:
                    db.query(models.DoseLog).filter(models.DoseLog.scheduled_reminder_id == reminder.id).delete()
                    reminder.status = "pending"
                    db.commit()

        # Seed Clinical Recommendations for Sarah Mitchell
        existing_recs = db.query(models.Recommendation).filter(models.Recommendation.case_id == case.id).count()
        if existing_recs == 0:
            recs = [
                models.Recommendation(
                    case_id=case.id,
                    text="Elevate leg above heart level for 30 minutes 3x daily",
                ),
                models.Recommendation(
                    case_id=case.id,
                    text="Apply ice pack to knee for 20 minutes after physical therapy exercises",
                ),
                models.Recommendation(
                    case_id=case.id,
                    text="Keep surgical incision clean and dry; do not submerge in water",
                ),
            ]
            db.add_all(recs)
            db.commit()
            print("Seeded clinical recommendations for Sarah Mitchell.")

        # Clean today's checkin on reset so check-in card is fresh
        if reset:
            db.query(models.CheckIn).filter(
                models.CheckIn.case_id == case.id,
                models.CheckIn.checkin_date == today,
            ).delete()
            db.commit()

        # Background Triage Roster Patients
        roster_data = [
            {
                "email": "john.davies@example.com",
                "name": "John Davies",
                "dob": "1961-09-23",
                "phone": "+1 555-0144",
                "surgery": "Total Hip Arthroplasty (THA)",
                "med_name": "Rivaroxaban",
                "dose": "10mg",
                "freq": "QD",
                "duration": "35 days",
                "status": "missed_dose", # Amber
                "checkin": models.CheckInFeeling.ok,
            },
            {
                "email": "emma.wilson@example.com",
                "name": "Emma Wilson",
                "dob": "1995-11-04",
                "phone": "+1 555-0182",
                "surgery": "Rotator Cuff Repair",
                "med_name": "Naproxen",
                "dose": "500mg",
                "freq": "BID",
                "duration": "10 days",
                "status": "not_great", # Amber
                "checkin": models.CheckInFeeling.not_great,
            },
            {
                "email": "maria.garcia@example.com",
                "name": "Maria Garcia",
                "dob": "1982-06-18",
                "phone": "+1 555-0163",
                "surgery": "ACL Reconstruction",
                "med_name": "Ibuprofen",
                "dose": "400mg",
                "freq": "BID",
                "duration": "14 days",
                "status": "great", # Green
                "checkin": models.CheckInFeeling.great,
            },
            {
                "email": "robert.chen@example.com",
                "name": "Robert Chen",
                "dob": "1966-02-14",
                "phone": "+1 555-0177",
                "surgery": "Lumbar Spinal Fusion (L4-L5)",
                "med_name": "Gabapentin",
                "dose": "300mg",
                "freq": "TID",
                "duration": "21 days",
                "status": "ok", # Green
                "checkin": models.CheckInFeeling.ok,
            },
        ]

        for p_info in roster_data:
            p_user = db.query(models.User).filter(models.User.email == p_info["email"]).first()
            if not p_user:
                p_user = models.User(
                    email=p_info["email"],
                    full_name=p_info["name"],
                    role=models.UserRole.patient,
                    status="active",
                    phone=p_info["phone"],
                    date_of_birth=p_info["dob"],
                    password_hash=hash_password(DEFAULT_PASSWORD),
                    invite_code="123456",
                    invite_code_expires_at=datetime.now(timezone.utc) + timedelta(days=365),
                )
                db.add(p_user)
                db.commit()
                db.refresh(p_user)

            p_case = db.query(models.Case).filter(models.Case.patient_id == p_user.id).first()
            if not p_case:
                p_case = models.Case(
                    clinician_id=clinician.id,
                    patient_id=p_user.id,
                    surgery_type=p_info["surgery"],
                    surgery_date=(today - timedelta(days=3)).isoformat(),
                    status="active",
                    emergency_contact_name="Dr. Sarah Connor",
                    emergency_contact_phone="+1 555-0122",
                )
                db.add(p_case)
                db.commit()
                db.refresh(p_case)

                p_med = models.Medication(
                    case_id=p_case.id,
                    name=p_info["med_name"],
                    dose=p_info["dose"],
                    schedule_text=p_info["freq"],
                    duration=p_info["duration"],
                    notes="Follow prescribed protocol",
                )
                db.add(p_med)
                db.commit()
                db.refresh(p_med)

                # Morning slot
                morning_dt = datetime.combine(today, time(8, 0))
                r1 = models.ScheduledReminder(
                    medication_id=p_med.id,
                    scheduled_time=morning_dt,
                    status="pending",
                )
                db.add(r1)
                db.commit()
                db.refresh(r1)

                if p_info["status"] == "missed_dose":
                    log1 = models.DoseLog(
                        scheduled_reminder_id=r1.id,
                        status=models.DoseStatus.missed,
                        logged_at=morning_dt + timedelta(hours=5),
                    )
                    db.add(log1)
                else:
                    log1 = models.DoseLog(
                        scheduled_reminder_id=r1.id,
                        status=models.DoseStatus.taken,
                        logged_at=morning_dt + timedelta(minutes=15),
                    )
                    db.add(log1)

                chk = models.CheckIn(
                    case_id=p_case.id,
                    feeling=p_info["checkin"],
                    checkin_date=today,
                )
                db.add(chk)
                db.commit()

        print("Seeded realistic roster patients (John Davies [Amber], Emma Wilson [Amber], Maria Garcia [Green], Robert Chen [Green]).")

        # Summary output
        print("\n" + "=" * 75)
        print("  RemoteCare Pro — SIMULATION 2: FULL DEMO SEED INITIALIZED")
        print("=" * 75)
        print("  CLINICIAN CREDENTIALS (Web Portal):")
        print("    • URL:      http://localhost:3000/login (or http://localhost:5173/login)")
        print("    • Email:    clinician@example.com")
        print("    • Password: password123")
        print("\n  PATIENT CREDENTIALS (Flutter Mobile App):")
        print("    • Email:    patient@example.com")
        print("    • 6-digit OTP Code: 424242 (Auto-pasting enabled)")
        print("    • Password: password123")
        print("    • Patient:  Sarah Mitchell (Total Knee Arthroplasty)")
        print("=" * 75 + "\n")

    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed database for RemoteCare Pro demo.")
    parser.add_argument(
        "--mode",
        choices=["full", "clinician-only"],
        default="full",
        help="Seed mode: 'clinician-only' (seeds only clinician for manual authoring) or 'full' (seeds entire demo state)",
    )
    parser.add_argument(
        "--clinician-only",
        action="store_true",
        help="Shortcut for --mode clinician-only",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="Shortcut for --mode full",
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Reset and wipe demo records before seeding",
    )
    args = parser.parse_args()

    mode = "clinician-only" if args.clinician_only else ("full" if args.full else args.mode)
    seed_database(mode=mode, reset=args.reset)
