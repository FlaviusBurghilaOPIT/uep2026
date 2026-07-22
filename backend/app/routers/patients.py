import csv
import io
import secrets
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user, require_clinician
from app.security import hash_password

router = APIRouter(
    prefix="/patients",
    tags=["patients"],
)



@router.post("/invite", response_model=schemas.PatientInviteResponse)
def invite_patient(
    req: schemas.PatientInviteRequest,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):
    existing_user = db.query(models.User).filter(models.User.email == req.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User with this email already exists")

    invite_code = f"{secrets.randbelow(900000) + 100000}"

    patient = models.User(
        email=req.email,
        full_name=req.full_name,
        role=models.UserRole.patient,
        status="pending_onboarding",
        invite_code=invite_code,
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)

    case = models.Case(
        clinician_id=current_user.id,
        patient_id=patient.id,
        surgery_type=req.surgery_type,
        emergency_contact_name=current_user.full_name,
        emergency_contact_phone=req.emergency_contact_phone,
        status="active",
    )
    db.add(case)
    db.commit()

    return schemas.PatientInviteResponse(
        patient_id=patient.id,
        invite_code=invite_code,
        email=patient.email,
        full_name=patient.full_name,
    )


@router.get("/", response_model=list[schemas.UserResponse])
def list_patients(
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    patients = db.query(models.User).filter(models.User.role == models.UserRole.patient).all()
    return patients


@router.post("/", response_model=schemas.UserResponse)
def create_patient(user: schemas.UserCreate, db: Session = Depends(get_db_for_user)):

    db_user = models.User(
        email=user.email,
        full_name=user.full_name,
        role=models.UserRole.patient,
        password_hash=hash_password(user.password),
        status="active",
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user


@router.get("/{patient_id}", response_model=schemas.UserResponse)
def get_patient(patient_id: str, db: Session = Depends(get_db_for_user)):

    patient = (
        db.query(models.User)
        .filter(models.User.id == patient_id, models.User.role == models.UserRole.patient)
        .first()
    )

    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    return patient


@router.get("/{patient_id}/case", response_model=schemas.CaseResponse)
def get_patient_case(patient_id: str, db: Session = Depends(get_db_for_user)):

    case = db.query(models.Case).filter(models.Case.patient_id == patient_id).first()

    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return case


@router.get("/{patient_id}/export")
def export_patient_telemetry(
    patient_id: str,
    format: str = Query("csv", description="Export format: csv or json"),
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    patient = (
        db.query(models.User)
        .filter(models.User.id == patient_id, models.User.role == models.UserRole.patient)
        .first()
    )

    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    case = db.query(models.Case).filter(models.Case.patient_id == patient_id).first()

    medications = (
        db.query(models.Medication).filter(models.Medication.case_id == case.id).all()
        if case
        else []
    )

    logs = (
        db.query(models.DoseLog)
        .join(
            models.ScheduledReminder,
            models.DoseLog.scheduled_reminder_id == models.ScheduledReminder.id,
        )
        .join(models.Medication, models.ScheduledReminder.medication_id == models.Medication.id)
        .join(models.Case, models.Medication.case_id == models.Case.id)
        .filter(models.Case.patient_id == patient_id)
        .all()
    )

    fmt = format.lower()
    if fmt not in ("csv", "json"):
        raise HTTPException(status_code=400, detail="Invalid format. Supported formats: csv, json")

    total_doses = len(logs)
    taken = sum(
        1
        for l in logs
        if (l.status.value if hasattr(l.status, "value") else str(l.status)) == "taken"
    )
    skipped = sum(
        1
        for l in logs
        if (l.status.value if hasattr(l.status, "value") else str(l.status)) == "skipped"
    )
    missed = sum(
        1
        for l in logs
        if (l.status.value if hasattr(l.status, "value") else str(l.status)) == "missed"
    )
    pending = sum(
        1
        for l in logs
        if (l.status.value if hasattr(l.status, "value") else str(l.status)) == "pending"
    )
    adherence_pct = round((taken / total_doses * 100), 2) if total_doses > 0 else 0.0

    if fmt == "json":
        return {
            "patient": {
                "id": patient.id,
                "full_name": patient.full_name,
                "email": patient.email,
                "status": patient.status,
            },
            "case": (
                {
                    "id": case.id,
                    "surgery_type": case.surgery_type,
                    "status": case.status,
                    "emergency_contact_name": case.emergency_contact_name,
                    "emergency_contact_phone": case.emergency_contact_phone,
                }
                if case
                else None
            ),
            "medications": [
                {
                    "id": m.id,
                    "name": m.name,
                    "dose": m.dose,
                    "schedule_text": m.schedule_text,
                    "duration": m.duration,
                    "notes": m.notes,
                }
                for m in medications
            ],
            "summary": {
                "total_doses": total_doses,
                "taken": taken,
                "skipped": skipped,
                "missed": missed,
                "pending": pending,
                "adherence_percentage": adherence_pct,
            },
            "dose_logs": [
                {
                    "id": log.id,
                    "scheduled_reminder_id": log.scheduled_reminder_id,
                    "status": (
                        log.status.value if hasattr(log.status, "value") else str(log.status)
                    ),
                    "logged_at": log.logged_at.isoformat() if log.logged_at else None,
                    "medication_name": (
                        log.scheduled_reminder.medication.name
                        if log.scheduled_reminder and log.scheduled_reminder.medication
                        else None
                    ),
                    "scheduled_time": (
                        log.scheduled_reminder.scheduled_time.isoformat()
                        if log.scheduled_reminder and log.scheduled_reminder.scheduled_time
                        else None
                    ),
                }
                for log in logs
            ],
        }

    output = io.StringIO()
    writer = csv.writer(output, lineterminator="\n")
    writer.writerow(["Date", "Medication", "ScheduledTime", "LoggedTime", "Status", "Notes"])

    for log in logs:
        date_str = ""
        if log.logged_at:
            date_str = log.logged_at.strftime("%Y-%m-%d")
        elif log.scheduled_reminder and log.scheduled_reminder.scheduled_time:
            date_str = log.scheduled_reminder.scheduled_time.strftime("%Y-%m-%d")

        med_name = ""
        notes = ""
        sched_time_str = ""
        if log.scheduled_reminder:
            if log.scheduled_reminder.scheduled_time:
                sched_time_str = log.scheduled_reminder.scheduled_time.isoformat()
            if log.scheduled_reminder.medication:
                med_name = log.scheduled_reminder.medication.name or ""
                notes = log.scheduled_reminder.medication.notes or ""

        logged_time_str = log.logged_at.isoformat() if log.logged_at else ""
        status_str = log.status.value if hasattr(log.status, "value") else str(log.status)

        writer.writerow([date_str, med_name, sched_time_str, logged_time_str, status_str, notes])

    csv_content = output.getvalue()
    date_str = datetime.utcnow().strftime("%Y-%m-%d")
    filename = f"patient_{patient_id}_telemetry_{date_str}.csv"

    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )

