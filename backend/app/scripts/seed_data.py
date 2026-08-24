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
import os
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


def get_utc_today() -> date:
    return datetime.now(timezone.utc).date()


def clean_demo_data(
    db: Session,
    keep_clinician: bool = False,
    clinician_email: str = "clinician@example.com",
    patient_email: str = "patient@example.com",
):
    """Wipes all demo records (cases, medications, logs, checkins, chat, patients)."""
    demo_emails = [
        patient_email,
        "john.davies@example.com",
        "emma.wilson@example.com",
        "maria.garcia@example.com",
        "robert.chen@example.com",
    ]
    if not keep_clinician:
        demo_emails.append(clinician_email)

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
        if not (keep_clinician and u.email == clinician_email):
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


def seed_database(
    mode: str = "full",
    reset: bool = False,
    clinician_email: str | None = None,
    clinician_password: str | None = None,
    patient_email: str | None = None,
    patient_otp: str | None = None,
    phoenix_admin_email: str | None = None,
    phoenix_admin_password: str | None = None,
):
    # Resolve configurable credentials (from args > env vars > secure defaults)
    c_email = clinician_email or os.getenv("CLINICIAN_EMAIL", "clinician@example.com")
    c_password = clinician_password or os.getenv("CLINICIAN_PASSWORD", "CarePro#2026!Secure")
    p_email = patient_email or os.getenv("DEMO_PATIENT_EMAIL", "patient@example.com")
    p_otp = patient_otp or os.getenv("DEMO_PATIENT_OTP", "424242")
    ph_admin_email = phoenix_admin_email or os.getenv("PHOENIX_ADMIN_EMAIL", "admin@localhost")
    ph_admin_pass = phoenix_admin_password or os.getenv("PHOENIX_ADMIN_PASSWORD", "Phoenix#2026!Guard")

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
            clean_demo_data(db, keep_clinician=False, clinician_email=c_email, patient_email=p_email)
            print("Cleaned existing demo user data.")
        elif mode == "clinician-only":
            # In clinician-only mode without full reset, ensure other demo patients/cases are removed
            clean_demo_data(db, keep_clinician=True, clinician_email=c_email, patient_email=p_email)

        # =========================================================================
        # 1. Clinician: Dr. Sarah Connor
        # =========================================================================
        clinician = db.query(models.User).filter(models.User.email == c_email).first()
        if not clinician:
            clinician = models.User(
                email=c_email,
                full_name="Dr. Sarah Connor",
                role=models.UserRole.clinician,
                password_hash=hash_password(c_password),
                status="active",
                phone="+1 555-0100",
            )
            db.add(clinician)
            db.commit()
            db.refresh(clinician)
            print(f"Created clinician: {c_email}")
        else:
            clinician.password_hash = hash_password(c_password)
            clinician.status = "active"
            db.commit()
            print(f"Verified clinician: {c_email}")

        # Load guidelines for AI assistant
        seed_guidelines_if_empty(db)

        # =========================================================================
        # MODE 1: Clinician Only Mode Exit
        # =========================================================================
        if mode == "clinician-only":
            print("\n" + "=" * 80)
            print("  🎉 RemoteCare Pro — SIMULATION 1: CLINICIAN-ONLY SEED INITIALIZED")
            print("=" * 80)
            print("  Ready for live authoring demo! No patients or cases currently exist.")
            print("  Log in to the Clinician Web Portal to create a patient and surgical case live.\n")
            print("  📋 CLINICIAN LOGIN CREDENTIALS (Web Portal):")
            print("    • Web Portal: http://<YOUR_EC2_IP> (Port 80) or http://localhost:3000/login")
            print(f"    • Email:      {c_email}")
            print(f"    • Password:   {c_password}\n")
            print("  📊 ARIZE PHOENIX (LLM Observability & Cost Tracking):")
            print(f"    • UI URL:     http://<YOUR_EC2_IP>:6006 (or http://localhost:6006)")
            print(f"    • Admin User: {ph_admin_email}")
            print(f"    • Password:   {ph_admin_pass}")
            print("=" * 80)
            print("  Share the Clinician Credentials with your mentor/evaluator to test live!")
            print("=" * 80 + "\n")
            return

        # =========================================================================
        # MODE 2: Full Simulation Mode (Patient + Case + Roster)
        # =========================================================================

        # Main Demo Patient: Sarah Mitchell
        patient = db.query(models.User).filter(models.User.email == p_email).first()
        if not patient:
            patient = models.User(
                email=p_email,
                full_name="Sarah Mitchell",
                role=models.UserRole.patient,
                status="active",
                invite_code=p_otp,
                invite_code_expires_at=datetime.now(timezone.utc) + timedelta(days=365),
                password_hash=hash_password(c_password),
                date_of_birth=date(1988, 4, 12),
                phone="+1 555-0199",
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
            print(f"Created patient: {p_email}")
        else:
            patient.invite_code = p_otp
            patient.invite_code_expires_at = datetime.now(timezone.utc) + timedelta(days=365)
            patient.status = "active"
            db.commit()
            print(f"Verified patient: {p_email}")

        # Active Surgical Case: Total Knee Arthroplasty (TKA)
        case = (
            db.query(models.Case)
            .filter(
                models.Case.patient_id == patient.id,
                models.Case.clinician_id == clinician.id,
                models.Case.surgery_type == "Total Knee Arthroplasty",
            )
            .first()
        )
        if not case:
            case = models.Case(
                patient_id=patient.id,
                clinician_id=clinician.id,
                surgery_type="Total Knee Arthroplasty",
                surgery_date=today - timedelta(days=3),
                status=models.CaseStatus.active,
                notes="Right knee primary TKA. Patient recovering well, moderate swelling expected. Cryotherapy 3x daily.",
                discharge_date=today - timedelta(days=2),
                emergency_contact_name="Dr. Sarah Connor",
                emergency_contact_phone="+1 555-0122",
            )
            db.add(case)
            db.commit()
            db.refresh(case)
            print(f"Created case: {case.surgery_type} for Sarah Mitchell")
        else:
            case.status = models.CaseStatus.active
            case.emergency_contact_name = "Dr. Sarah Connor"
            case.emergency_contact_phone = "+1 555-0122"
            db.commit()

        # Demo Prescriptions: Ibuprofen, Amoxicillin, Oxycodone
        meds_data = [
            {
                "name": "Ibuprofen",
                "dosage": "400mg",
                "form": models.MedicationForm.tablet,
                "frequency": models.FrequencyType.bid,
                "route": "oral",
                "schedule_times": ["08:00", "20:00"],
                "instructions": "Take with meals or milk to reduce stomach upset.",
                "duration_days": 10,
                "prescribed_days": 10,
                "is_prn": False,
                "is_scheduled": True,
            },
            {
                "name": "Amoxicillin",
                "dosage": "500mg",
                "form": models.MedicationForm.capsule,
                "frequency": models.FrequencyType.bid,
                "route": "oral",
                "schedule_times": ["08:00", "20:00"],
                "instructions": "Complete the entire course as prescribed.",
                "duration_days": 7,
                "prescribed_days": 7,
                "is_prn": False,
                "is_scheduled": True,
            },
            {
                "name": "Oxycodone",
                "dosage": "5mg",
                "form": models.MedicationForm.tablet,
                "frequency": models.FrequencyType.prn,
                "route": "oral",
                "schedule_times": [],
                "instructions": "Take as needed for severe breakthrough pain. Maximum 4 per day.",
                "duration_days": 5,
                "prescribed_days": 5,
                "is_prn": True,
                "is_scheduled": False,
            },
        ]

        for m_data in meds_data:
            existing_med = (
                db.query(models.Medication)
                .filter(
                    models.Medication.case_id == case.id,
                    models.Medication.name == m_data["name"],
                )
                .first()
            )
            if not existing_med:
                med = models.Medication(
                    case_id=case.id,
                    name=m_data["name"],
                    dosage=m_data["dosage"],
                    form=m_data["form"],
                    frequency=m_data["frequency"],
                    route=m_data["route"],
                    schedule_times=m_data["schedule_times"],
                    instructions=m_data["instructions"],
                    duration_days=m_data["duration_days"],
                    prescribed_days=m_data["prescribed_days"],
                    is_prn=m_data["is_prn"],
                    is_scheduled=m_data["is_scheduled"],
                    start_date=today - timedelta(days=2),
                )
                db.add(med)
                db.commit()
                db.refresh(med)

                # Generate scheduled reminders for today
                if med.is_scheduled and med.schedule_times:
                    for t_str in med.schedule_times:
                        hh, mm = map(int, t_str.split(":"))
                        sched_dt = datetime.combine(today, time(hh, mm), tzinfo=timezone.utc)
                        rem = models.ScheduledReminder(
                            case_id=case.id,
                            medication_id=med.id,
                            scheduled_time=sched_dt,
                            status=models.ReminderStatus.pending,
                        )
                        db.add(rem)
                    db.commit()
                print(f"Created prescription: {med.name} {med.dosage} ({med.frequency.value})")

        # Care Instructions / Recommendations
        recs = [
            "Keep the surgical dressing clean, dry, and intact until follow-up appointment.",
            "Perform gentle ankle pumps (10 repetitions every hour while awake) to prevent blood clots.",
            "Apply cryotherapy / ice pack for 20 minutes every 3-4 hours to control local swelling.",
        ]
        for rec_text in recs:
            existing_rec = (
                db.query(models.Recommendation)
                .filter(
                    models.Recommendation.case_id == case.id,
                    models.Recommendation.text == rec_text,
                )
                .first()
            )
            if not existing_rec:
                rec = models.Recommendation(
                    case_id=case.id,
                    text=rec_text,
                    category="Post-Op Care",
                )
                db.add(rec)
        db.commit()

        # =========================================================================
        # 3. Background Triage Roster Patients (Amber & Green)
        # =========================================================================
        roster_patients = [
            {
                "email": "john.davies@example.com",
                "name": "John Davies",
                "dob": date(1965, 8, 14),
                "surgery": "Total Hip Arthroplasty",
                "days_ago": 4,
                "med_name": "Celecoxib",
                "dosage": "200mg",
                "form": models.MedicationForm.capsule,
                "freq": models.FrequencyType.bid,
                "status": "missed_dose",
                "checkin": "ok",
            },
            {
                "email": "emma.wilson@example.com",
                "name": "Emma Wilson",
                "dob": date(1979, 11, 23),
                "surgery": "Rotator Cuff Repair",
                "days_ago": 2,
                "med_name": "Tramadol",
                "dosage": "50mg",
                "form": models.MedicationForm.tablet,
                "freq": models.FrequencyType.bid,
                "status": "active",
                "checkin": "not_great",
            },
            {
                "email": "maria.garcia@example.com",
                "name": "Maria Garcia",
                "dob": date(1992, 3, 5),
                "surgery": "ACL Reconstruction",
                "days_ago": 6,
                "med_name": "Naproxen",
                "dosage": "500mg",
                "form": models.MedicationForm.tablet,
                "freq": models.FrequencyType.bid,
                "status": "active",
                "checkin": "great",
            },
            {
                "email": "robert.chen@example.com",
                "name": "Robert Chen",
                "dob": date(1971, 7, 30),
                "surgery": "Spinal Fusion",
                "days_ago": 5,
                "med_name": "Gabapentin",
                "dosage": "300mg",
                "form": models.MedicationForm.capsule,
                "freq": models.FrequencyType.tid,
                "status": "active",
                "checkin": "ok",
            },
        ]

        for p_info in roster_patients:
            p_user = db.query(models.User).filter(models.User.email == p_info["email"]).first()
            if not p_user:
                p_user = models.User(
                    email=p_info["email"],
                    full_name=p_info["name"],
                    role=models.UserRole.patient,
                    status="active",
                    password_hash=hash_password(c_password),
                    date_of_birth=p_info["dob"],
                    phone="+1 555-0155",
                )
                db.add(p_user)
                db.commit()
                db.refresh(p_user)

            p_case = (
                db.query(models.Case)
                .filter(
                    models.Case.patient_id == p_user.id,
                    models.Case.clinician_id == clinician.id,
                )
                .first()
            )
            if not p_case:
                p_case = models.Case(
                    patient_id=p_user.id,
                    clinician_id=clinician.id,
                    surgery_type=p_info["surgery"],
                    surgery_date=today - timedelta(days=p_info["days_ago"]),
                    status=models.CaseStatus.active,
                    notes=f"{p_info['surgery']} routine recovery follow-up.",
                    discharge_date=today - timedelta(days=p_info["days_ago"] - 1),
                )
                db.add(p_case)
                db.commit()
                db.refresh(p_case)

                p_med = models.Medication(
                    case_id=p_case.id,
                    name=p_info["med_name"],
                    dosage=p_info["dosage"],
                    form=p_info["form"],
                    frequency=p_info["freq"],
                    route="oral",
                    schedule_times=["08:00", "20:00"],
                    duration_days=10,
                    prescribed_days=10,
                    start_date=today - timedelta(days=2),
                )
                db.add(p_med)
                db.commit()
                db.refresh(p_med)

                morning_dt = datetime.combine(today, time(8, 0), tzinfo=timezone.utc)
                r1 = models.ScheduledReminder(
                    case_id=p_case.id,
                    medication_id=p_med.id,
                    scheduled_time=morning_dt,
                    status=models.ReminderStatus.taken if p_info["status"] != "missed_dose" else models.ReminderStatus.missed,
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
        print("\n" + "=" * 80)
        print("  🎉 RemoteCare Pro — SIMULATION 2: FULL DEMO SEED INITIALIZED")
        print("=" * 80)
        print("  📋 CLINICIAN LOGIN CREDENTIALS (Web Portal):")
        print("    • Web Portal: http://<YOUR_EC2_IP> (Port 80) or http://localhost:3000/login")
        print(f"    • Email:      {c_email}")
        print(f"    • Password:   {c_password}\n")
        print("  📱 PATIENT DEMO CREDENTIALS (Flutter Mobile App):")
        print(f"    • Email:      {p_email}")
        print(f"    • 6-digit OTP Code: {p_otp} (Auto-pasting enabled)")
        print("    • Case:       Sarah Mitchell (Total Knee Arthroplasty)\n")
        print("  📊 ARIZE PHOENIX (LLM Observability & Cost Tracking):")
        print("    • UI URL:     http://<YOUR_EC2_IP>:6006 (or http://localhost:6006)")
        print(f"    • Admin User: {ph_admin_email}")
        print(f"    • Password:   {ph_admin_pass}")
        print("=" * 80)
        print("  Share the Clinician Credentials with your mentor/evaluator to test live!")
        print("=" * 80 + "\n")

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
    parser.add_argument(
        "--clinician-email",
        default=None,
        help="Custom clinician email (defaults to CLINICIAN_EMAIL env or clinician@example.com)",
    )
    parser.add_argument(
        "--clinician-password",
        default=None,
        help="Custom clinician password (defaults to CLINICIAN_PASSWORD env or CarePro#2026!Secure)",
    )
    parser.add_argument(
        "--patient-email",
        default=None,
        help="Custom patient email (defaults to DEMO_PATIENT_EMAIL env or patient@example.com)",
    )
    parser.add_argument(
        "--patient-otp",
        default=None,
        help="Custom patient OTP code (defaults to DEMO_PATIENT_OTP env or 424242)",
    )
    args = parser.parse_args()

    mode = "clinician-only" if args.clinician_only else ("full" if args.full else args.mode)
    seed_database(
        mode=mode,
        reset=args.reset,
        clinician_email=args.clinician_email,
        clinician_password=args.clinician_password,
        patient_email=args.patient_email,
        patient_otp=args.patient_otp,
    )
