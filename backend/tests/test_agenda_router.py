from datetime import date, datetime, timedelta

import pytest

from app import models
from app.routers import agenda as agenda_module
from app.security import create_access_token
from app.services.schedule_parser import create_scheduled_reminders_for_day

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


def _token(user):
    return create_access_token(
        {"sub": user.id, "role": user.role.value, "email": user.email}
    )


def _headers(user):
    return {"Authorization": f"Bearer {_token(user)}"}


def _make_case(db_session, clinician, patient):
    case = models.Case(
        clinician_id=clinician.id, patient_id=patient.id, surgery_type="ACL Repair"
    )
    db_session.add(case)
    db_session.commit()
    return case


def _make_med(db_session, case, name, frequency, dose="400mg", notes=None):
    med = models.Medication(
        case_id=case.id,
        name=name,
        dose=dose,
        schedule_text=frequency,
        duration="7 days",
        notes=notes,
    )
    db_session.add(med)
    db_session.commit()
    return med


def _patient_fixture(db_session, suffix=""):
    clinician = _make_user(
        db_session, f"doc{suffix}@example.com", f"Dr {suffix}", models.UserRole.clinician
    )
    patient = _make_user(
        db_session, f"pat{suffix}@example.com", f"Pat {suffix}", models.UserRole.patient
    )
    case = _make_case(db_session, clinician, patient)
    return clinician, patient, case


def _get_agenda(client, user, day=AGENDA_DATE):
    return client.get(
        "/patients/me/agenda",
        params={"date": day.isoformat()},
        headers=_headers(user),
    )


def test_agenda_states_at_frozen_now(client, db_session, frozen_now):
    _, patient, case = _patient_fixture(db_session, "-states")
    med_qd = _make_med(db_session, case, "MedQD", "QD")
    med_bid = _make_med(db_session, case, "MedBID", "BID")
    med_tid = _make_med(db_session, case, "MedTID", "TID")

    # First call materializes today's slots (ensure-on-read).
    first = _get_agenda(client, patient)
    assert first.status_code == 200
    slot_by_med_hour = {
        (s["medication_id"], s["scheduled_time"][11:13]): s["slot_id"]
        for s in first.json()["slots"]
    }

    # Log the 08:00 BID slot as taken and the 08:00 TID slot as skipped.
    for slot_id, status in (
        (slot_by_med_hour[(med_bid.id, "08")], "taken"),
        (slot_by_med_hour[(med_tid.id, "08")], "skipped"),
    ):
        resp = client.post(
            "/adherence/log",
            params={"scheduled_reminder_id": slot_id, "status": status},
            headers=_headers(patient),
        )
        assert resp.status_code == 200

    second = _get_agenda(client, patient)
    assert second.status_code == 200
    body = second.json()
    assert body["date"] == "2026-07-26"

    def state_for(med_id, hour):
        for s in body["slots"]:
            if s["medication_id"] == med_id and s["scheduled_time"][11:13] == f"{hour:02d}":
                return s["state"]
        raise AssertionError(f"slot missing for {med_id} at {hour}")

    # Frozen now = 13:00. Windows: due = [sched-2h, sched+4h].
    assert state_for(med_qd.id, 8) == "missed"  # 13:00 > 08:00 + 4h
    assert state_for(med_bid.id, 8) == "taken"  # log wins
    assert state_for(med_bid.id, 20) == "upcoming"  # 13:00 < 20:00 - 2h
    assert state_for(med_tid.id, 8) == "skipped"  # log wins
    assert state_for(med_tid.id, 13) == "due"  # 13:00 within [11:00, 17:00]
    assert state_for(med_tid.id, 20) == "upcoming"


def test_agenda_slot_shape_and_utc_serialization(client, db_session, frozen_now):
    _, patient, case = _patient_fixture(db_session, "-shape")
    med = _make_med(db_session, case, "Ibuprofen", "QD", dose="400 mg", notes="with food")

    response = _get_agenda(client, patient)
    assert response.status_code == 200
    (slot,) = response.json()["slots"]
    assert set(slot.keys()) == {
        "slot_id",
        "medication_id",
        "medication_name",
        "dose",
        "notes",
        "scheduled_time",
        "state",
        "logged_at",
        "dose_log_id",
        "previous_status",
    }
    assert slot["medication_id"] == med.id
    assert slot["medication_name"] == "Ibuprofen"
    assert slot["dose"] == "400 mg"
    assert slot["notes"] == "with food"
    assert slot["scheduled_time"] == "2026-07-26T08:00:00Z"
    assert slot["state"] == "missed"
    assert slot["logged_at"] is None
    assert slot["dose_log_id"] is None
    assert slot["previous_status"] is None


def test_ensure_on_read_materializes_once_with_stable_slot_ids(
    client, db_session, frozen_now
):
    _, patient, case = _patient_fixture(db_session, "-ensure")
    med = _make_med(db_session, case, "MedTID", "TID")

    first = _get_agenda(client, patient)
    assert first.status_code == 200
    first_ids = [s["slot_id"] for s in first.json()["slots"]]
    assert len(first_ids) == 3

    day_start = datetime.combine(AGENDA_DATE, datetime.min.time())
    day_end = day_start + timedelta(days=1)
    count = (
        db_session.query(models.ScheduledReminder)
        .filter(
            models.ScheduledReminder.medication_id == med.id,
            models.ScheduledReminder.scheduled_time >= day_start,
            models.ScheduledReminder.scheduled_time < day_end,
        )
        .count()
    )
    assert count == 3

    # Double-call (concurrent-safe path): same slots, no duplicates.
    second = _get_agenda(client, patient)
    assert second.status_code == 200
    assert [s["slot_id"] for s in second.json()["slots"]] == first_ids
    assert (
        db_session.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.medication_id == med.id)
        .count()
        == 3
    )


def test_create_scheduled_reminders_for_day_is_idempotent(db_session):
    clinician, patient, case = _patient_fixture(db_session, "-perday")
    med = _make_med(db_session, case, "MedBID", "BID")

    created = create_scheduled_reminders_for_day(db_session, med, AGENDA_DATE)
    assert len(created) == 2
    db_session.commit()

    again = create_scheduled_reminders_for_day(db_session, med, AGENDA_DATE)
    assert again == []
    assert (
        db_session.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.medication_id == med.id)
        .count()
        == 2
    )


def test_prn_medication_only_in_prn_array(client, db_session, frozen_now):
    _, patient, case = _patient_fixture(db_session, "-prn")
    prn_med = _make_med(
        db_session, case, "Tramadol", "PRN", dose="50 mg", notes="if pain"
    )
    _make_med(db_session, case, "MedQD", "QD")

    response = _get_agenda(client, patient)
    assert response.status_code == 200
    body = response.json()

    assert body["prn"] == [
        {
            "medication_id": prn_med.id,
            "medication_name": "Tramadol",
            "dose": "50 mg",
            "notes": "if pain",
        }
    ]
    assert all(s["medication_id"] != prn_med.id for s in body["slots"])
    assert (
        db_session.query(models.ScheduledReminder)
        .filter(models.ScheduledReminder.medication_id == prn_med.id)
        .count()
        == 0
    )


def test_agenda_forbidden_for_clinician(client, db_session, frozen_now):
    clinician, _, _ = _patient_fixture(db_session, "-clin")

    response = _get_agenda(client, clinician)
    assert response.status_code == 403


def test_agenda_requires_auth(client):
    response = client.get("/patients/me/agenda", params={"date": "2026-07-26"})
    assert response.status_code in (401, 403)


def test_agenda_only_returns_own_cases_slots(client, db_session, frozen_now):
    _, patient_a, case_a = _patient_fixture(db_session, "-a")
    _, patient_b, case_b = _patient_fixture(db_session, "-b")
    med_a = _make_med(db_session, case_a, "MedA", "QD")
    med_b = _make_med(db_session, case_b, "MedB", "QD")

    body_a = _get_agenda(client, patient_a).json()
    assert {s["medication_id"] for s in body_a["slots"]} == {med_a.id}

    body_b = _get_agenda(client, patient_b).json()
    assert {s["medication_id"] for s in body_b["slots"]} == {med_b.id}


def test_previous_status_from_latest_correction_event(client, db_session, frozen_now):
    _, patient, case = _patient_fixture(db_session, "-corr")
    _make_med(db_session, case, "MedQD", "QD")

    first = _get_agenda(client, patient)
    slot_id = first.json()["slots"][0]["slot_id"]
    resp = client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": slot_id, "status": "taken"},
        headers=_headers(patient),
    )
    assert resp.status_code == 200
    log_id = resp.json()["id"]

    # Simulate a correction (WI 08 PATCH): append event, update the log.
    log = db_session.query(models.DoseLog).filter(models.DoseLog.id == log_id).first()
    event = models.DoseLogEvent(
        dose_log_id=log.id,
        old_status=models.DoseStatus.taken,
        new_status=models.DoseStatus.skipped,
    )
    log.status = models.DoseStatus.skipped
    log.corrected_at = FROZEN_NOW
    db_session.add(event)
    db_session.commit()

    body = _get_agenda(client, patient).json()
    (slot,) = body["slots"]
    assert slot["state"] == "skipped"
    assert slot["dose_log_id"] == log_id
    assert slot["previous_status"] == "taken"
    assert slot["logged_at"] is not None and slot["logged_at"].endswith("Z")


def test_agenda_empty_for_patient_without_cases(client, db_session, frozen_now):
    patient = _make_user(
        db_session, "lonely@example.com", "Lonely", models.UserRole.patient
    )

    response = _get_agenda(client, patient)
    assert response.status_code == 200
    assert response.json() == {"date": "2026-07-26", "slots": [], "prn": []}
