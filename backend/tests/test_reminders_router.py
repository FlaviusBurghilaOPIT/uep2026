from datetime import datetime, timedelta

import pytest

from app import models
from app.security import create_access_token


def _make_user(db_session, email, name, role):
    user = models.User(email=email, full_name=name, role=role)
    db_session.add(user)
    db_session.commit()
    return user


def _make_case_with_reminder(db_session, clinician, patient, med_name="Ibuprofen"):
    case = models.Case(
        clinician_id=clinician.id, patient_id=patient.id, surgery_type="ACL Repair"
    )
    db_session.add(case)
    db_session.commit()
    medication = models.Medication(
        case_id=case.id,
        name=med_name,
        dose="400mg",
        schedule_text="3x daily",
        duration="14 days",
    )
    db_session.add(medication)
    db_session.commit()
    reminder = models.ScheduledReminder(
        medication_id=medication.id, scheduled_time=datetime.utcnow() + timedelta(hours=1)
    )
    db_session.add(reminder)
    db_session.commit()
    return case, medication, reminder


def _token(user, role):
    return create_access_token({"sub": user.id, "role": role, "email": user.email})


@pytest.fixture()
def two_patient_setup(db_session):
    clinician_a = _make_user(db_session, "docA@t.com", "Doc A", models.UserRole.clinician)
    clinician_b = _make_user(db_session, "docB@t.com", "Doc B", models.UserRole.clinician)
    patient_a = _make_user(db_session, "patA@t.com", "Pat A", models.UserRole.patient)
    patient_b = _make_user(db_session, "patB@t.com", "Pat B", models.UserRole.patient)

    _, med_a, reminder_a = _make_case_with_reminder(db_session, clinician_a, patient_a, "MedA")
    _, med_b, reminder_b = _make_case_with_reminder(db_session, clinician_b, patient_b, "MedB")

    return {
        "clinician_a": clinician_a,
        "clinician_b": clinician_b,
        "patient_a": patient_a,
        "patient_b": patient_b,
        "med_a": med_a,
        "med_b": med_b,
        "reminder_a": reminder_a,
        "reminder_b": reminder_b,
    }


def _headers(user, role):
    return {"Authorization": f"Bearer {_token(user, role)}"}


def test_patient_a_sees_zero_of_patient_b_reminders(client, db_session, two_patient_setup):
    s = two_patient_setup
    response = client.get("/reminders/", headers=_headers(s["patient_a"], "patient"))

    assert response.status_code == 200
    ids = [r["id"] for r in response.json()]
    assert s["reminder_a"].id in ids
    assert s["reminder_b"].id not in ids


def test_clinician_sees_only_own_cases_reminders(client, db_session, two_patient_setup):
    s = two_patient_setup
    response = client.get("/reminders/", headers=_headers(s["clinician_a"], "clinician"))

    assert response.status_code == 200
    ids = [r["id"] for r in response.json()]
    assert s["reminder_a"].id in ids
    assert s["reminder_b"].id not in ids


def test_patient_post_reminder_forbidden(client, db_session, two_patient_setup):
    s = two_patient_setup
    response = client.post(
        "/reminders/",
        json={
            "medication_id": s["med_a"].id,
            "scheduled_time": datetime.utcnow().isoformat(),
        },
        headers=_headers(s["patient_a"], "patient"),
    )
    assert response.status_code == 403


def test_patient_patch_reminder_forbidden(client, db_session, two_patient_setup):
    s = two_patient_setup
    response = client.patch(
        f"/reminders/{s['reminder_a'].id}",
        params={"status": "taken"},
        headers=_headers(s["patient_a"], "patient"),
    )
    assert response.status_code == 403


def test_clinician_post_reminder_for_own_case_succeeds(client, db_session, two_patient_setup):
    s = two_patient_setup
    response = client.post(
        "/reminders/",
        json={
            "medication_id": s["med_a"].id,
            "scheduled_time": datetime.utcnow().isoformat(),
        },
        headers=_headers(s["clinician_a"], "clinician"),
    )
    assert response.status_code == 200
    assert response.json()["medication_id"] == s["med_a"].id


def test_clinician_post_reminder_for_other_clinicians_case_forbidden(
    client, db_session, two_patient_setup
):
    s = two_patient_setup
    response = client.post(
        "/reminders/",
        json={
            "medication_id": s["med_b"].id,
            "scheduled_time": datetime.utcnow().isoformat(),
        },
        headers=_headers(s["clinician_a"], "clinician"),
    )
    assert response.status_code == 403


def test_clinician_post_reminder_unknown_medication_404(client, db_session, two_patient_setup):
    s = two_patient_setup
    response = client.post(
        "/reminders/",
        json={
            "medication_id": "nonexistent-med-id",
            "scheduled_time": datetime.utcnow().isoformat(),
        },
        headers=_headers(s["clinician_a"], "clinician"),
    )
    assert response.status_code == 404


def test_clinician_patch_own_reminder_succeeds(client, db_session, two_patient_setup):
    s = two_patient_setup
    response = client.patch(
        f"/reminders/{s['reminder_a'].id}",
        params={"status": "taken"},
        headers=_headers(s["clinician_a"], "clinician"),
    )
    assert response.status_code == 200
    assert response.json()["status"] == "taken"


def test_clinician_patch_other_clinicians_reminder_forbidden(
    client, db_session, two_patient_setup
):
    s = two_patient_setup
    response = client.patch(
        f"/reminders/{s['reminder_b'].id}",
        params={"status": "taken"},
        headers=_headers(s["clinician_a"], "clinician"),
    )
    assert response.status_code == 403


def test_clinician_patch_unknown_reminder_404(client, db_session, two_patient_setup):
    s = two_patient_setup
    response = client.patch(
        "/reminders/nonexistent-reminder-id",
        params={"status": "taken"},
        headers=_headers(s["clinician_a"], "clinician"),
    )
    assert response.status_code == 404
