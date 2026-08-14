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


def test_export_patient_telemetry_csv(client, db_session):
    reminder, token = _seed_reminder(db_session)
    headers = {"Authorization": f"Bearer {token}"}

    # Log a dose first
    client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder.id, "status": "taken"},
        headers=headers,
    )

    patient_id = reminder.medication.case.patient_id
    response = client.get(f"/patients/{patient_id}/export", headers=headers)

    assert response.status_code == 200
    assert response.headers["Content-Type"].startswith("text/csv")
    content_disp = response.headers.get("Content-Disposition", "")
    assert "attachment;" in content_disp
    assert f"patient_{patient_id}_telemetry_" in content_disp
    assert content_disp.endswith('.csv"') or content_disp.endswith(".csv")

    csv_text = response.text
    lines = [line.strip() for line in csv_text.strip().split("\n") if line.strip()]
    assert len(lines) >= 2
    assert lines[0] == "Date,Medication,ScheduledTime,LoggedTime,Status,Notes"
    assert "Ibuprofen" in lines[1]
    assert "taken" in lines[1]


def test_export_patient_telemetry_json(client, db_session):
    reminder, token = _seed_reminder(db_session)
    headers = {"Authorization": f"Bearer {token}"}

    client.post(
        "/adherence/log",
        params={"scheduled_reminder_id": reminder.id, "status": "taken"},
        headers=headers,
    )

    patient_id = reminder.medication.case.patient_id
    response = client.get(f"/patients/{patient_id}/export?format=json", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert data["patient"]["id"] == patient_id
    assert data["summary"]["total_doses"] == 1
    assert data["summary"]["taken"] == 1
    assert data["summary"]["adherence_percentage"] == 100.0
    assert len(data["dose_logs"]) == 1
    assert data["dose_logs"][0]["status"] == "taken"


def test_export_patient_telemetry_not_found(client, db_session):
    reminder, token = _seed_reminder(db_session)
    headers = {"Authorization": f"Bearer {token}"}

    response = client.get("/patients/nonexistent-patient-id/export", headers=headers)
    assert response.status_code == 404

