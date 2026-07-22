from datetime import datetime, timedelta

from app import models
from app.security import create_access_token


def _seed_reminder(db_session):
    clinician = models.User(email="c@t.com", full_name="C", role=models.UserRole.clinician)
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db_session.add(case)
    db_session.commit()

    medication = models.Medication(
        case_id=case.id, name="Ibuprofen", dose="400mg", schedule_text="3x daily", duration="14 days"
    )
    db_session.add(medication)
    db_session.commit()

    reminder = models.ScheduledReminder(
        medication_id=medication.id, scheduled_time=datetime.utcnow() + timedelta(hours=1)
    )
    db_session.add(reminder)
    db_session.commit()

    token = create_access_token({"sub": patient.id, "role": "patient", "email": patient.email})
    return reminder, token


def test_log_dose_succeeds_on_first_post(client, db_session):
    reminder, token = _seed_reminder(db_session)

    response = client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder.id, "status": "taken"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json()["scheduled_reminder_id"] == reminder.id


def test_duplicate_log_returns_409_not_500(client, db_session):
    reminder, token = _seed_reminder(db_session)
    headers = {"Authorization": f"Bearer {token}"}

    first = client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder.id, "status": "taken"},
        headers=headers,
    )
    assert first.status_code == 200
    first_log_id = first.json()["id"]

    second = client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder.id, "status": "skipped"},
        headers=headers,
    )

    assert second.status_code == 409
    body = second.json()["detail"]
    assert body["id"] == first_log_id
    assert body["scheduled_reminder_id"] == reminder.id


def test_two_different_reminders_both_succeed(client, db_session):
    reminder_a, token = _seed_reminder(db_session)
    medication = (
        db_session.query(models.Medication)
        .filter(models.Medication.id == reminder_a.medication_id)
        .first()
    )
    reminder_b = models.ScheduledReminder(
        medication_id=medication.id, scheduled_time=datetime.utcnow() + timedelta(hours=2)
    )
    db_session.add(reminder_b)
    db_session.commit()

    headers = {"Authorization": f"Bearer {token}"}
    response_a = client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder_a.id, "status": "taken"},
        headers=headers,
    )
    response_b = client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder_b.id, "status": "missed"},
        headers=headers,
    )

    assert response_a.status_code == 200
    assert response_b.status_code == 200
