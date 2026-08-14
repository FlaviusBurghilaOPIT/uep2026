"""Server-driven patient agenda — spec E2
(ai_specs/2026-07-26-adherence-pipeline-backend-spec.md §6 E2).

The mobile Today screen renders these slots with zero client-side schedule
parsing: times and states are server truth. Slots are materialized lazily
("ensure-on-read") so legacy medications and prescribe-time failures self-heal.
"""

from datetime import date, datetime, time, timedelta
from typing import Final

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user
from app.services.schedule_parser import (
    create_scheduled_reminders_for_day,
    times_for_frequency,
)

router = APIRouter(
    prefix="/patients",
    tags=["agenda"],
)

# Due/missed windows (spec §10-D1): values pending clinical validation;
# isolated as named constants so they can be tuned without schema or
# contract change.
DUE_WINDOW_BEFORE: Final = timedelta(hours=2)
DUE_WINDOW_AFTER: Final = timedelta(hours=4)

_LOGGED_STATES: Final = {s.value for s in schemas.SlotState}


def _compute_state(
    reminder: models.ScheduledReminder,
    dose_log: models.DoseLog | None,
    now: datetime,
) -> schemas.SlotState:
    """Server-computed slot state (spec §6 E2).

    A log's status wins when it is a renderable state (taken/skipped/missed);
    otherwise fall back to the time windows.
    """
    if dose_log is not None and dose_log.status is not None:
        value = (
            dose_log.status.value
            if hasattr(dose_log.status, "value")
            else str(dose_log.status)
        )
        if value in _LOGGED_STATES:
            return schemas.SlotState(value)

    scheduled = reminder.scheduled_time
    if now < scheduled - DUE_WINDOW_BEFORE:
        return schemas.SlotState.upcoming
    if now > scheduled + DUE_WINDOW_AFTER:
        return schemas.SlotState.missed
    return schemas.SlotState.due


@router.get("/me/agenda", response_model=schemas.AgendaResponse)
def get_my_agenda(
    agenda_date: date = Query(..., alias="date"),
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    # Identity comes from the JWT only — no path parameter, no IDOR surface.
    if current_user.role != models.UserRole.patient:
        raise HTTPException(status_code=403, detail="Patient access required")

    now = datetime.utcnow()

    cases = (
        db.query(models.Case).filter(models.Case.patient_id == current_user.id).all()
    )
    case_ids = [c.id for c in cases]
    if not case_ids:
        return schemas.AgendaResponse(date=agenda_date, slots=[], prn=[])

    medications = (
        db.query(models.Medication)
        .filter(models.Medication.case_id.in_(case_ids))
        .all()
    )

    active_meds = []
    discontinued_meds = []
    for med in medications:
        if med.discontinued_at is None:
            active_meds.append(med)
        else:
            discontinued_meds.append(med)

    scheduled_meds = []
    prn = []
    for med in active_meds:
        if times_for_frequency(med.schedule_text):
            scheduled_meds.append(med)
        else:
            prn.append(
                schemas.AgendaPrnMedication(
                    medication_id=med.id,
                    medication_name=med.name,
                    dose=med.dose,
                    notes=med.notes,
                )
            )

    # Ensure-on-read: idempotently materialize this date's slots (check-then-
    # insert on (medication_id, scheduled_time); concurrent-safe). Active meds
    # only — discontinued meds never grow new slots.
    for med in scheduled_meds:
        create_scheduled_reminders_for_day(db, med, agenda_date)
    db.commit()

    slots = _slots_for_date(db, scheduled_meds, agenda_date, now)

    # Spec E4: a discontinued med's past slots (scheduled_time <=
    # discontinued_at) and logged slots remain as history; future unlogged
    # slots are excluded.
    slots += _slots_for_date(
        db,
        discontinued_meds,
        agenda_date,
        now,
        row_filter=lambda reminder, log, med: log is not None
        or reminder.scheduled_time <= med.discontinued_at,
    )
    slots.sort(key=lambda s: (s.scheduled_time, s.slot_id))
    return schemas.AgendaResponse(date=agenda_date, slots=slots, prn=prn)


def _slots_for_date(
    db: Session,
    medications: list[models.Medication],
    agenda_date: date,
    now: datetime,
    row_filter=None,
) -> list[schemas.AgendaSlot]:
    if not medications:
        return []

    day_start = datetime.combine(agenda_date, time.min)
    day_end = day_start + timedelta(days=1)
    med_by_id = {m.id: m for m in medications}

    rows = (
        db.query(models.ScheduledReminder, models.DoseLog)
        .outerjoin(
            models.DoseLog,
            models.DoseLog.scheduled_reminder_id == models.ScheduledReminder.id,
        )
        .filter(
            models.ScheduledReminder.medication_id.in_(med_by_id.keys()),
            models.ScheduledReminder.scheduled_time >= day_start,
            models.ScheduledReminder.scheduled_time < day_end,
        )
        .order_by(models.ScheduledReminder.scheduled_time)
        .all()
    )

    log_ids = [log.id for _, log in rows if log is not None]
    latest_event_by_log: dict[str, models.DoseLogEvent] = {}
    if log_ids:
        events = (
            db.query(models.DoseLogEvent)
            .filter(models.DoseLogEvent.dose_log_id.in_(log_ids))
            .order_by(models.DoseLogEvent.changed_at.desc())
            .all()
        )
        for event in events:  # first seen per log = most recent (desc order)
            latest_event_by_log.setdefault(event.dose_log_id, event)

    slots = []
    for reminder, log in rows:
        med = med_by_id[reminder.medication_id]
        if row_filter is not None and not row_filter(reminder, log, med):
            continue
        previous_status = None
        if log is not None:
            event = latest_event_by_log.get(log.id)
            if event is not None:
                previous_status = event.old_status
        slots.append(
            schemas.AgendaSlot(
                slot_id=reminder.id,
                medication_id=med.id,
                medication_name=med.name,
                dose=med.dose,
                notes=med.notes,
                scheduled_time=reminder.scheduled_time,
                state=_compute_state(reminder, log, now),
                logged_at=log.logged_at if log is not None else None,
                dose_log_id=log.id if log is not None else None,
                previous_status=previous_status,
            )
        )
    return slots
