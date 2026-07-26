from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user

router = APIRouter(
    prefix="/adherence",
    tags=["adherence"],
)


def _require_case_access(
    medication: models.Medication,
    current_user: models.User,
    *,
    patient_only: bool = False,
) -> None:
    """Ownership check via reminder/medication → case.

    403 unless the current user is the case's patient or (unless
    ``patient_only``) the case's clinician. Correction is patient-only v1
    (spec §6 E1 — clinician correction out of scope).
    """
    case = medication.case
    allowed = case.patient_id == current_user.id
    if not patient_only:
        allowed = allowed or case.clinician_id == current_user.id
    if not allowed:
        raise HTTPException(status_code=403, detail="Not authorized for this resource")


def _latest_event_old_status(db: Session, dose_log_id: str) -> models.DoseStatus | None:
    event = (
        db.query(models.DoseLogEvent)
        .filter(models.DoseLogEvent.dose_log_id == dose_log_id)
        .order_by(models.DoseLogEvent.changed_at.desc())
        .first()
    )
    return event.old_status if event else None


def _build_adhoc_response(
    db: Session,
    reminder: models.ScheduledReminder,
    dose_log: models.DoseLog,
) -> schemas.AdhocLogResponse:
    medication = reminder.medication
    previous_status = _latest_event_old_status(db, dose_log.id)
    slot = schemas.AgendaSlot(
        slot_id=reminder.id,
        medication_id=medication.id,
        medication_name=medication.name,
        dose=medication.dose,
        notes=medication.notes,
        scheduled_time=reminder.scheduled_time,
        state=schemas.SlotState(dose_log.status.value),
        logged_at=dose_log.logged_at,
        dose_log_id=dose_log.id,
        previous_status=previous_status,
    )
    return schemas.AdhocLogResponse(
        slot=slot,
        dose_log=schemas.DoseLogCorrectResponse(
            id=dose_log.id,
            scheduled_reminder_id=dose_log.scheduled_reminder_id,
            status=dose_log.status,
            previous_status=previous_status,
            logged_at=dose_log.logged_at,
            corrected_at=dose_log.corrected_at,
        ),
    )


@router.post("/log")
def log_dose(
    scheduled_reminder_id: str,
    status: models.DoseStatus,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    reminder = (
        db.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.id == scheduled_reminder_id)
        .first()
    )

    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    _require_case_access(reminder.medication, current_user)

    # Keep the legacy reminder.status column in sync in the same transaction
    # (spec §6 E1 — web clinician view still reads it; deprecated long-term).
    reminder.status = status.value

    dose_log = models.DoseLog(
        scheduled_reminder_id=scheduled_reminder_id, status=status, logged_at=datetime.utcnow()
    )

    db.add(dose_log)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = (
            db.query(models.DoseLog)
            .filter(models.DoseLog.scheduled_reminder_id == scheduled_reminder_id)
            .first()
        )
        raise HTTPException(
            status_code=409,
            detail={
                "message": "Dose already logged for this reminder",
                "id": existing.id,
                "scheduled_reminder_id": existing.scheduled_reminder_id,
                "status": existing.status,
                "logged_at": existing.logged_at.isoformat() if existing.logged_at else None,
            },
        )

    db.refresh(dose_log)

    return dose_log


@router.post("/log-adhoc", status_code=201, response_model=schemas.AdhocLogResponse)
def log_dose_adhoc(
    body: schemas.AdhocLogRequest,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    """PRN (as-needed) dose logging (spec §6 E1).

    Atomically creates the ScheduledReminder slot + DoseLog. Idempotent via
    client-supplied key: a retry with a known key returns the original 201
    body without creating duplicates (offline-queue retry safety).
    """
    if body.status == models.DoseStatus.pending:
        raise HTTPException(
            status_code=400, detail="status must be terminal (taken, skipped, or missed)"
        )

    medication = (
        db.query(models.Medication).filter(models.Medication.id == body.medication_id).first()
    )
    if not medication:
        raise HTTPException(status_code=404, detail="Medication not found")

    _require_case_access(medication, current_user)

    if medication.discontinued_at is not None:
        raise HTTPException(status_code=400, detail="Medication is discontinued")
    if medication.schedule_text.strip().upper() != "PRN":
        raise HTTPException(
            status_code=400, detail="Ad-hoc logging is only allowed for PRN medications"
        )

    existing = (
        db.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.idempotency_key == body.idempotency_key)
        .first()
    )
    if existing:
        return _build_adhoc_response(db, existing, existing.dose_log)

    taken_at = body.taken_at
    if taken_at is not None and taken_at.tzinfo is not None:
        # Stored as naive UTC (spec E2 serialization rule).
        taken_at = taken_at.astimezone(timezone.utc).replace(tzinfo=None)

    now = datetime.utcnow()
    reminder = models.ScheduledReminder(
        medication_id=medication.id,
        scheduled_time=taken_at or now,
        status=body.status.value,
        idempotency_key=body.idempotency_key,
    )
    db.add(reminder)
    db.flush()

    dose_log = models.DoseLog(scheduled_reminder_id=reminder.id, status=body.status, logged_at=now)
    db.add(dose_log)

    try:
        db.commit()
    except IntegrityError:
        # Concurrent retry with the same key won the race — return the original.
        db.rollback()
        existing = (
            db.query(models.ScheduledReminder)
            .filter(models.ScheduledReminder.idempotency_key == body.idempotency_key)
            .first()
        )
        if existing:
            return _build_adhoc_response(db, existing, existing.dose_log)
        raise

    db.refresh(reminder)
    db.refresh(dose_log)

    return _build_adhoc_response(db, reminder, dose_log)


@router.patch("/logs/{log_id}", response_model=schemas.DoseLogCorrectResponse)
def correct_dose_log(
    log_id: str,
    body: schemas.DoseLogCorrectRequest,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    """Correct a logged dose status (spec §6 E1).

    Transaction: append a dose_log_events audit row (old → new), update
    dose_logs.status + corrected_at, and sync scheduled_reminders.status.
    Patient-only v1 (clinician correction out of scope; the events table
    already accommodates it).
    """
    dose_log = db.query(models.DoseLog).filter(models.DoseLog.id == log_id).first()
    if not dose_log:
        raise HTTPException(status_code=404, detail="Dose log not found")

    reminder = dose_log.scheduled_reminder
    _require_case_access(reminder.medication, current_user, patient_only=True)

    old_status = dose_log.status
    if body.status == old_status:
        raise HTTPException(status_code=400, detail="Status unchanged")

    now = datetime.utcnow()
    db.add(
        models.DoseLogEvent(dose_log_id=dose_log.id, old_status=old_status, new_status=body.status)
    )
    dose_log.status = body.status
    dose_log.corrected_at = now
    reminder.status = body.status.value
    db.commit()
    db.refresh(dose_log)

    return schemas.DoseLogCorrectResponse(
        id=dose_log.id,
        scheduled_reminder_id=dose_log.scheduled_reminder_id,
        status=dose_log.status,
        previous_status=old_status,
        logged_at=dose_log.logged_at,
        corrected_at=dose_log.corrected_at,
    )


@router.get("/patients/{patient_id}", response_model=list[schemas.DoseLogDetailResponse])
def get_patient_adherence(
    patient_id: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

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

    return [
        schemas.DoseLogDetailResponse(
            id=log.id,
            scheduled_reminder_id=log.scheduled_reminder_id,
            status=log.status.value if hasattr(log.status, "value") else str(log.status),
            logged_at=log.logged_at,
            medication_name=(
                log.scheduled_reminder.medication.name
                if log.scheduled_reminder and log.scheduled_reminder.medication
                else None
            ),
            scheduled_time=(
                log.scheduled_reminder.scheduled_time if log.scheduled_reminder else None
            ),
        )
        for log in logs
    ]


@router.get("/patients/{patient_id}/export")
def export_patient_telemetry_adherence(
    patient_id: str,
    format: str = "csv",
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    from app.routers.patients import export_patient_telemetry

    return export_patient_telemetry(
        patient_id=patient_id, format=format, db=db, current_user=current_user
    )
