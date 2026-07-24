from datetime import datetime

from app import models
from app.security import create_access_token


def _make_users(db_session):
    clinician = models.User(email="c@t.com", full_name="Dr C", role=models.UserRole.clinician)
    patient = models.User(email="p@t.com", full_name="Pat P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()
    return clinician, patient


def _clinician_headers(clinician):
    token = create_access_token(
        {"sub": clinician.id, "role": "clinician", "email": clinician.email}
    )
    return {"Authorization": f"Bearer {token}"}


def test_resolve_triage_alert_persists_resolution(client, db_session):
    clinician, patient = _make_users(db_session)

    response = client.post(
        f"/patients/{patient.id}/triage-resolve",
        json={"outreach_method": "phone_call", "clinical_note": "Called, patient fine."},
        headers=_clinician_headers(clinician),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["patient_id"] == patient.id
    assert body["clinician_id"] == clinician.id
    assert body["outreach_method"] == "phone_call"
    assert body["clinical_note"] == "Called, patient fine."
    assert body["resolved_at"]

    stored = db_session.query(models.TriageResolution).one()
    assert stored.patient_id == patient.id


def test_resolve_triage_alert_requires_note(client, db_session):
    clinician, patient = _make_users(db_session)

    response = client.post(
        f"/patients/{patient.id}/triage-resolve",
        json={"outreach_method": "phone_call", "clinical_note": "   "},
        headers=_clinician_headers(clinician),
    )

    assert response.status_code == 400


def test_resolve_triage_alert_unknown_patient(client, db_session):
    clinician, _ = _make_users(db_session)

    response = client.post(
        "/patients/does-not-exist/triage-resolve",
        json={"outreach_method": "phone_call", "clinical_note": "note"},
        headers=_clinician_headers(clinician),
    )

    assert response.status_code == 404


def test_latest_triage_resolutions_returns_newest_per_patient(client, db_session):
    clinician, patient = _make_users(db_session)
    headers = _clinician_headers(clinician)

    client.post(
        f"/patients/{patient.id}/triage-resolve",
        json={"outreach_method": "phone_call", "clinical_note": "first"},
        headers=headers,
    )
    client.post(
        f"/patients/{patient.id}/triage-resolve",
        json={"outreach_method": "secure_sms", "clinical_note": "second"},
        headers=headers,
    )

    response = client.get("/patients/triage-resolutions/latest", headers=headers)

    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["patient_id"] == patient.id


def test_triage_resolve_rejects_patient_role(client, db_session):
    _, patient = _make_users(db_session)
    token = create_access_token({"sub": patient.id, "role": "patient", "email": patient.email})

    response = client.post(
        f"/patients/{patient.id}/triage-resolve",
        json={"outreach_method": "phone_call", "clinical_note": "note"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code in (401, 403)


def test_adherence_returns_medication_name_and_scheduled_time(client, db_session):
    clinician, patient = _make_users(db_session)
    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db_session.add(case)
    db_session.commit()

    med = models.Medication(
        case_id=case.id,
        name="Ibuprofen",
        dose="400mg",
        schedule_text="QD",
        duration="14 days",
    )
    db_session.add(med)
    db_session.commit()

    reminder = models.ScheduledReminder(
        medication_id=med.id, scheduled_time=datetime(2026, 7, 25, 8, 0)
    )
    db_session.add(reminder)
    db_session.commit()

    db_session.add(
        models.DoseLog(
            scheduled_reminder_id=reminder.id,
            status=models.DoseStatus.taken,
            logged_at=datetime(2026, 7, 25, 8, 42),
        )
    )
    db_session.commit()

    token = create_access_token(
        {"sub": clinician.id, "role": "clinician", "email": clinician.email}
    )
    response = client.get(
        f"/adherence/patients/{patient.id}",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["medication_name"] == "Ibuprofen"
    assert body[0]["scheduled_time"].startswith("2026-07-25T08:00")
    assert body[0]["status"] == "taken"
    assert body[0]["logged_at"].startswith("2026-07-25T08:42")
