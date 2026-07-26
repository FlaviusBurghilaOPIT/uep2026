"""Tests for WI 08 — adherence write API.

Covers ai_specs/work-items/08-adherence-write-api.md acceptance criteria:
- POST /adherence/log: 409 contract pinned, ownership (403), reminder status sync
- POST /adherence/log-adhoc: atomic slot+log, idempotency-key retry, 400 guards
- PATCH /adherence/logs/{log_id}: correction + audit chain, 400/403/404
"""

from datetime import datetime

from app import models
from app.security import create_access_token


def _make_user(db, email, role):
    user = models.User(email=email, full_name=email.split("@")[0], role=role)
    db.add(user)
    db.commit()
    return user


def _token(user, role="patient"):
    return create_access_token({"sub": user.id, "role": role, "email": user.email})


def _auth(user, role="patient"):
    return {"Authorization": f"Bearer {_token(user, role)}"}


def _seed_case(db, *, schedule_text="TID", discontinued=False):
    """Create clinician + patient + case + medication (+ one reminder).

    Returns (clinician, patient, case, medication, reminder-or-None).
    """
    clinician = _make_user(db, "clin@t.com", models.UserRole.clinician)
    patient = _make_user(db, "pat@t.com", models.UserRole.patient)
    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db.add(case)
    db.commit()
    medication = models.Medication(
        case_id=case.id,
        name="Ibuprofen",
        dose="400mg",
        schedule_text=schedule_text,
        duration="14 days",
        notes="with food",
        discontinued_at=datetime.utcnow() if discontinued else None,
    )
    db.add(medication)
    db.commit()
    reminder = None
    if schedule_text != "PRN":
        reminder = models.ScheduledReminder(
            medication_id=medication.id,
            scheduled_time=datetime(2026, 7, 26, 8, 0, 0),
        )
        db.add(reminder)
        db.commit()
    return clinician, patient, case, medication, reminder


def _post_log(client, reminder_id, headers, status="taken"):
    return client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder_id, "status": status},
        headers=headers,
    )


# --- POST /adherence/log -----------------------------------------------------


def test_log_409_contract_pinned(client, db_session):
    _, patient, _, _, reminder = _seed_case(db_session)
    headers = _auth(patient)

    first = _post_log(client, reminder.id, headers)
    assert first.status_code == 200

    second = _post_log(client, reminder.id, headers, status="skipped")
    assert second.status_code == 409
    detail = second.json()["detail"]
    assert detail["message"] == "Dose already logged for this reminder"
    assert detail["id"] == first.json()["id"]
    assert detail["scheduled_reminder_id"] == reminder.id
    assert detail["status"] == "taken"
    assert detail["logged_at"] is not None

    # No duplicate row created.
    logs = db_session.query(models.DoseLog).all()
    assert len(logs) == 1


def test_log_unknown_reminder_404(client, db_session):
    _, patient, _, _, _ = _seed_case(db_session)
    response = _post_log(client, "nonexistent-id", _auth(patient))
    assert response.status_code == 404


def test_log_syncs_reminder_status_in_same_transaction(client, db_session):
    _, patient, _, _, reminder = _seed_case(db_session)

    response = _post_log(client, reminder.id, _auth(patient), status="taken")
    assert response.status_code == 200

    db_session.expire_all()
    synced = (
        db_session.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.id == reminder.id)
        .first()
    )
    assert synced.status == "taken"


def test_log_duplicate_does_not_overwrite_reminder_status(client, db_session):
    _, patient, _, _, reminder = _seed_case(db_session)
    headers = _auth(patient)

    assert _post_log(client, reminder.id, headers, status="taken").status_code == 200
    assert _post_log(client, reminder.id, headers, status="skipped").status_code == 409

    db_session.expire_all()
    assert (
        db_session.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.id == reminder.id)
        .first()
        .status
        == "taken"
    )


def test_log_ownership_patient_b_forbidden(client, db_session):
    _, _, _, _, reminder = _seed_case(db_session)
    patient_b = _make_user(db_session, "patb@t.com", models.UserRole.patient)

    response = _post_log(client, reminder.id, _auth(patient_b))
    assert response.status_code == 403
    assert db_session.query(models.DoseLog).count() == 0


def test_log_ownership_case_clinician_allowed(client, db_session):
    clinician, _, _, _, reminder = _seed_case(db_session)

    response = _post_log(client, reminder.id, _auth(clinician, role="clinician"))
    assert response.status_code == 200


def test_log_ownership_unrelated_clinician_forbidden(client, db_session):
    _, _, _, _, reminder = _seed_case(db_session)
    other_clinician = _make_user(db_session, "other@t.com", models.UserRole.clinician)

    response = _post_log(client, reminder.id, _auth(other_clinician, role="clinician"))
    assert response.status_code == 403


# --- POST /adherence/log-adhoc ----------------------------------------------


def _post_adhoc(client, medication_id, headers, key="key-1", status="taken", taken_at=None):
    body = {"medication_id": medication_id, "status": status, "idempotency_key": key}
    if taken_at is not None:
        body["taken_at"] = taken_at
    return client.post("/adherence/log-adhoc", json=body, headers=headers)


def test_adhoc_creates_slot_and_log_atomically(client, db_session):
    _, patient, _, medication, _ = _seed_case(db_session, schedule_text="PRN")

    response = _post_adhoc(client, medication.id, _auth(patient), taken_at="2026-07-26T14:30:00Z")
    assert response.status_code == 201
    body = response.json()

    slot = body["slot"]
    assert slot["medication_id"] == medication.id
    assert slot["medication_name"] == "Ibuprofen"
    assert slot["dose"] == "400mg"
    assert slot["notes"] == "with food"
    assert slot["scheduled_time"] == "2026-07-26T14:30:00Z"
    assert slot["state"] == "taken"
    assert slot["previous_status"] is None
    assert slot["dose_log_id"] == body["dose_log"]["id"]
    assert slot["logged_at"] is not None
    assert slot["slot_id"] == body["dose_log"]["scheduled_reminder_id"]

    reminder = (
        db_session.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.id == slot["slot_id"])
        .first()
    )
    assert reminder is not None
    assert reminder.idempotency_key == "key-1"
    assert reminder.status == "taken"
    assert reminder.scheduled_time == datetime(2026, 7, 26, 14, 30, 0)

    log = (
        db_session.query(models.DoseLog)
        .filter(models.DoseLog.scheduled_reminder_id == reminder.id)
        .first()
    )
    assert log is not None
    assert log.status == models.DoseStatus.taken


def test_adhoc_defaults_taken_at_to_now(client, db_session):
    _, patient, _, medication, _ = _seed_case(db_session, schedule_text="PRN")

    before = datetime.utcnow()
    response = _post_adhoc(client, medication.id, _auth(patient))
    after = datetime.utcnow()

    assert response.status_code == 201
    reminder = db_session.query(models.ScheduledReminder).one()
    assert before <= reminder.scheduled_time <= after


def test_adhoc_idempotent_retry_returns_original_no_duplicate(client, db_session):
    _, patient, _, medication, _ = _seed_case(db_session, schedule_text="PRN")
    headers = _auth(patient)

    first = _post_adhoc(client, medication.id, headers, key="retry-key")
    assert first.status_code == 201

    second = _post_adhoc(client, medication.id, headers, key="retry-key")
    assert second.status_code == 201
    assert second.json() == first.json()

    assert db_session.query(models.ScheduledReminder).count() == 1
    assert db_session.query(models.DoseLog).count() == 1

    # A different key is a new dose.
    third = _post_adhoc(client, medication.id, headers, key="other-key")
    assert third.status_code == 201
    assert third.json()["slot"]["slot_id"] != first.json()["slot"]["slot_id"]
    assert db_session.query(models.DoseLog).count() == 2


def test_adhoc_400_on_non_prn_medication(client, db_session):
    _, patient, _, medication, _ = _seed_case(db_session, schedule_text="TID")

    response = _post_adhoc(client, medication.id, _auth(patient))
    assert response.status_code == 400
    assert db_session.query(models.ScheduledReminder).count() == 1  # seeded one only
    assert db_session.query(models.DoseLog).count() == 0


def test_adhoc_400_on_discontinued_medication(client, db_session):
    _, patient, _, medication, _ = _seed_case(db_session, schedule_text="PRN", discontinued=True)

    response = _post_adhoc(client, medication.id, _auth(patient))
    assert response.status_code == 400
    assert db_session.query(models.ScheduledReminder).count() == 0
    assert db_session.query(models.DoseLog).count() == 0


def test_adhoc_400_on_pending_status(client, db_session):
    _, patient, _, medication, _ = _seed_case(db_session, schedule_text="PRN")

    response = _post_adhoc(client, medication.id, _auth(patient), status="pending")
    assert response.status_code == 400


def test_adhoc_404_unknown_medication(client, db_session):
    _, patient, _, _, _ = _seed_case(db_session, schedule_text="PRN")

    response = _post_adhoc(client, "nonexistent-id", _auth(patient))
    assert response.status_code == 404


def test_adhoc_ownership_patient_b_forbidden(client, db_session):
    _, _, _, medication, _ = _seed_case(db_session, schedule_text="PRN")
    patient_b = _make_user(db_session, "patb@t.com", models.UserRole.patient)

    response = _post_adhoc(client, medication.id, _auth(patient_b))
    assert response.status_code == 403
    assert db_session.query(models.DoseLog).count() == 0


# --- PATCH /adherence/logs/{log_id} -----------------------------------------


def _logged_dose(client, db_session, status="taken"):
    """Seed a case, log a dose, return (patient, clinician, reminder, log_id)."""
    clinician, patient, _, _, reminder = _seed_case(db_session)
    response = _post_log(client, reminder.id, _auth(patient), status=status)
    assert response.status_code == 200
    return patient, clinician, reminder, response.json()["id"]


def _patch_log(client, log_id, headers, status):
    return client.patch(f"/adherence/logs/{log_id}", json={"status": status}, headers=headers)


def test_correction_updates_log_appends_event_syncs_reminder(client, db_session):
    patient, _, reminder, log_id = _logged_dose(client, db_session)

    response = _patch_log(client, log_id, _auth(patient), "skipped")
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == log_id
    assert body["scheduled_reminder_id"] == reminder.id
    assert body["status"] == "skipped"
    assert body["previous_status"] == "taken"
    assert body["corrected_at"] is not None
    assert body["logged_at"] is not None

    db_session.expire_all()
    log = db_session.query(models.DoseLog).filter(models.DoseLog.id == log_id).first()
    assert log.status == models.DoseStatus.skipped
    assert log.corrected_at is not None

    events = (
        db_session.query(models.DoseLogEvent)
        .filter(models.DoseLogEvent.dose_log_id == log_id)
        .all()
    )
    assert len(events) == 1
    assert events[0].old_status == models.DoseStatus.taken
    assert events[0].new_status == models.DoseStatus.skipped

    synced = (
        db_session.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.id == reminder.id)
        .first()
    )
    assert synced.status == "skipped"


def test_correction_two_successive_produce_two_ordered_events(client, db_session):
    patient, _, _, log_id = _logged_dose(client, db_session)
    headers = _auth(patient)

    first = _patch_log(client, log_id, headers, "skipped")
    assert first.status_code == 200
    assert first.json()["previous_status"] == "taken"

    second = _patch_log(client, log_id, headers, "missed")
    assert second.status_code == 200
    assert second.json()["previous_status"] == "skipped"
    assert second.json()["status"] == "missed"

    events = (
        db_session.query(models.DoseLogEvent)
        .filter(models.DoseLogEvent.dose_log_id == log_id)
        .order_by(models.DoseLogEvent.changed_at)
        .all()
    )
    assert len(events) == 2
    assert (events[0].old_status, events[0].new_status) == (
        models.DoseStatus.taken,
        models.DoseStatus.skipped,
    )
    assert (events[1].old_status, events[1].new_status) == (
        models.DoseStatus.skipped,
        models.DoseStatus.missed,
    )
    assert events[1].changed_at >= events[0].changed_at


def test_correction_400_status_unchanged(client, db_session):
    patient, _, _, log_id = _logged_dose(client, db_session)

    response = _patch_log(client, log_id, _auth(patient), "taken")
    assert response.status_code == 400
    assert db_session.query(models.DoseLogEvent).count() == 0


def test_correction_404_unknown_log(client, db_session):
    _, patient, _, _, _ = _seed_case(db_session)

    response = _patch_log(client, "nonexistent-id", _auth(patient), "skipped")
    assert response.status_code == 404


def test_correction_403_cross_patient(client, db_session):
    _, _, _, log_id = _logged_dose(client, db_session)
    patient_b = _make_user(db_session, "patb@t.com", models.UserRole.patient)

    response = _patch_log(client, log_id, _auth(patient_b), "skipped")
    assert response.status_code == 403
    assert db_session.query(models.DoseLogEvent).count() == 0


def test_correction_403_clinician_patient_only_v1(client, db_session):
    _, clinician, _, log_id = _logged_dose(client, db_session)

    response = _patch_log(client, log_id, _auth(clinician, role="clinician"), "skipped")
    assert response.status_code == 403
    assert db_session.query(models.DoseLogEvent).count() == 0
