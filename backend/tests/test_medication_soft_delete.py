from datetime import date, datetime, timedelta

import pytest

from app import models
from app.routers import agenda as agenda_module
from app.security import create_access_token

FROZEN_NOW = datetime(2026, 7, 26, 13, 0, 0)  # naive UTC
AGENDA_DATE = date(2026, 7, 26)


class _FrozenDateTime(datetime):
    @classmethod
    def utcnow(cls):
        return FROZEN_NOW


@pytest.fixture()
def frozen_now(monkeypatch):
    monkeypatch.setattr(agenda_module, "datetime", _FrozenDateTime)
    return FROZEN_NOW


def _make_user(db_session, email, name, role):
    user = models.User(email=email, full_name=name, role=role)
    db_session.add(user)
    db_session.commit()
    return user


def _headers(user):
    token = create_access_token(
        {"sub": user.id, "role": user.role.value, "email": user.email}
    )
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def care_team(db_session):
    clinician = _make_user(
        db_session, "doc@example.com", "Dr House", models.UserRole.clinician
    )
    patient = _make_user(
        db_session, "pat@example.com", "Patient", models.UserRole.patient
    )
    case = models.Case(
        clinician_id=clinician.id, patient_id=patient.id, surgery_type="ACL Repair"
    )
    db_session.add(case)
    db_session.commit()
    return clinician, patient, case


def _make_med(db_session, case, name, frequency, dose="400mg"):
    med = models.Medication(
        case_id=case.id,
        name=name,
        dose=dose,
        schedule_text=frequency,
        duration="7 days",
    )
    db_session.add(med)
    db_session.commit()
    return med


def _get_agenda(client, user, day=AGENDA_DATE):
    return client.get(
        "/patients/me/agenda",
        params={"date": day.isoformat()},
        headers=_headers(user),
    )


def test_delete_discontinues_without_removing_rows(client, db_session, care_team):
    clinician, patient, case = care_team
    med = _make_med(db_session, case, "Ibuprofen", "QD")
    reminder = models.ScheduledReminder(
        medication_id=med.id, scheduled_time=FROZEN_NOW - timedelta(hours=5)
    )
    db_session.add(reminder)
    db_session.commit()
    log = models.DoseLog(
        scheduled_reminder_id=reminder.id,
        status=models.DoseStatus.taken,
        logged_at=FROZEN_NOW - timedelta(hours=5),
    )
    db_session.add(log)
    db_session.commit()

    response = client.delete(f"/medications/{med.id}", headers=_headers(clinician))
    assert response.status_code == 200
    assert response.json() == {"message": "Medication discontinued"}

    # Nothing is deleted; the med is flagged instead.
    persisted = (
        db_session.query(models.Medication)
        .filter(models.Medication.id == med.id)
        .first()
    )
    assert persisted is not None
    assert persisted.discontinued_at is not None
    assert (
        db_session.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.medication_id == med.id)
        .count()
        == 1
    )
    assert (
        db_session.query(models.DoseLog).filter(models.DoseLog.id == log.id).count()
        == 1
    )


def test_delete_medication_forbidden_for_patient(client, db_session, care_team):
    _, patient, case = care_team
    med = _make_med(db_session, case, "Ibuprofen", "QD")

    response = client.delete(f"/medications/{med.id}", headers=_headers(patient))
    assert response.status_code == 403
    assert (
        db_session.query(models.Medication)
        .filter(models.Medication.id == med.id)
        .first()
        .discontinued_at
        is None
    )


def test_delete_medication_forbidden_for_non_owner_clinician(
    client, db_session, care_team
):
    _, _, case = care_team
    med = _make_med(db_session, case, "Ibuprofen", "QD")
    other_clinician = _make_user(
        db_session, "other@example.com", "Dr Other", models.UserRole.clinician
    )

    response = client.delete(
        f"/medications/{med.id}", headers=_headers(other_clinician)
    )
    assert response.status_code == 403


def test_delete_medication_unknown_404(client, db_session, care_team):
    clinician, _, _ = care_team

    response = client.delete("/medications/nope", headers=_headers(clinician))
    assert response.status_code == 404


def test_case_medications_hides_discontinued_by_default(client, db_session, care_team):
    clinician, _, case = care_team
    keep = _make_med(db_session, case, "Paracetamol", "BID")
    drop = _make_med(db_session, case, "Ibuprofen", "QD")

    response = client.delete(f"/medications/{drop.id}", headers=_headers(clinician))
    assert response.status_code == 200

    default = client.get(f"/cases/{case.id}/medications", headers=_headers(clinician))
    assert default.status_code == 200
    assert [m["id"] for m in default.json()] == [keep.id]

    # Response shape unchanged (clinician web depends on it).
    assert set(default.json()[0].keys()) == {
        "id",
        "case_id",
        "name",
        "dose",
        "frequency",
        "schedule_times",
        "duration",
        "notes",
        "created_at",
        "scheduled_reminders",
    }

    full = client.get(
        f"/cases/{case.id}/medications",
        params={"include_discontinued": "true"},
        headers=_headers(clinician),
    )
    assert full.status_code == 200
    assert {m["id"] for m in full.json()} == {keep.id, drop.id}


def test_adherence_history_preserved_after_discontinue(client, db_session, care_team):
    clinician, patient, case = care_team
    med = _make_med(db_session, case, "Ibuprofen", "QD")
    reminder = models.ScheduledReminder(
        medication_id=med.id, scheduled_time=FROZEN_NOW - timedelta(hours=5)
    )
    db_session.add(reminder)
    db_session.commit()

    log_resp = client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder.id, "status": "taken"},
        headers=_headers(patient),
    )
    assert log_resp.status_code == 200

    delete_resp = client.delete(f"/medications/{med.id}", headers=_headers(clinician))
    assert delete_resp.status_code == 200

    history = client.get(
        f"/adherence/patients/{patient.id}", headers=_headers(clinician)
    )
    assert history.status_code == 200
    logs = history.json()
    assert len(logs) == 1
    assert logs[0]["medication_name"] == "Ibuprofen"
    assert logs[0]["status"] == "taken"
    assert logs[0]["scheduled_reminder_id"] == reminder.id


def test_agenda_after_discontinue_keeps_history_drops_future_unlogged(
    client, db_session, care_team, frozen_now
):
    clinician, patient, case = care_team
    med = _make_med(db_session, case, "MedTID", "TID")
    prn_med = _make_med(db_session, case, "Tramadol", "PRN", dose="50 mg")

    # Materialize today's slots and log the 08:00 one.
    first = _get_agenda(client, patient)
    assert first.status_code == 200
    slot_by_hour = {s["scheduled_time"][11:13]: s for s in first.json()["slots"]}
    assert set(slot_by_hour.keys()) == {"08", "13", "20"}
    log_resp = client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": slot_by_hour["08"]["slot_id"], "status": "taken"},
        headers=_headers(patient),
    )
    assert log_resp.status_code == 200

    # Discontinue mid-course (13:00 frozen): 08:00 logged and 13:00 past
    # unlogged stay; 20:00 future unlogged goes.
    med.discontinued_at = FROZEN_NOW
    prn_med.discontinued_at = FROZEN_NOW
    db_session.commit()

    body = _get_agenda(client, patient).json()
    hours = {s["scheduled_time"][11:13]: s["state"] for s in body["slots"]}
    assert hours == {"08": "taken", "13": "due"}

    # Discontinued PRN med is excluded from the prn array.
    assert body["prn"] == []

    # No new slots are materialized for a discontinued med on a later date.
    later = _get_agenda(client, patient, day=AGENDA_DATE + timedelta(days=1))
    assert later.status_code == 200
    assert later.json()["slots"] == []
