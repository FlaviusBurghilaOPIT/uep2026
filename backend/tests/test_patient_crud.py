"""Patient/case CRUD: PATCH /patients/{id}, DELETE /patients/{id} (soft
deactivate), POST /patients/{id}/reactivate, PATCH /cases/{case_id}."""

from app import models
from app.security import create_access_token


def _user(db_session, email, role, **kwargs):
    user = models.User(
        email=email,
        full_name=kwargs.pop("full_name", email.split("@")[0]),
        role=role,
        status=kwargs.pop("status", "active"),
        **kwargs,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def _headers(user):
    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"Authorization": f"Bearer {token}"}


def _case(db_session, clinician, patient, **kwargs):
    case = models.Case(
        clinician_id=clinician.id,
        patient_id=patient.id,
        surgery_type=kwargs.pop("surgery_type", "knee"),
        status=kwargs.pop("status", "active"),
        **kwargs,
    )
    db_session.add(case)
    db_session.commit()
    db_session.refresh(case)
    return case


# --- PATCH /patients/{patient_id} ---


def test_clinician_updates_patient_fields(client, db_session):
    clinician = _user(db_session, "clinician@example.com", models.UserRole.clinician)
    patient = _user(db_session, "patient@example.com", models.UserRole.patient, full_name="Old Name")

    response = client.patch(
        f"/patients/{patient.id}",
        json={"full_name": "New Name", "phone": "+1-555-0100"},
        headers=_headers(clinician),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["full_name"] == "New Name"
    assert body["phone"] == "+1-555-0100"


def test_patient_cannot_edit_via_clinician_only_endpoint(client, db_session):
    patient = _user(db_session, "patient@example.com", models.UserRole.patient)

    response = client.patch(
        f"/patients/{patient.id}",
        json={"full_name": "Hacked"},
        headers=_headers(patient),
    )

    assert response.status_code == 403


def test_update_unknown_patient_404(client, db_session):
    clinician = _user(db_session, "clinician@example.com", models.UserRole.clinician)

    response = client.patch(
        "/patients/does-not-exist",
        json={"full_name": "Nobody"},
        headers=_headers(clinician),
    )

    assert response.status_code == 404


# --- DELETE /patients/{patient_id} (soft deactivate) ---


def test_clinician_deactivates_patient(client, db_session):
    clinician = _user(db_session, "clinician@example.com", models.UserRole.clinician)
    patient = _user(db_session, "patient@example.com", models.UserRole.patient)
    case = _case(db_session, clinician, patient)

    response = client.delete(f"/patients/{patient.id}", headers=_headers(clinician))

    assert response.status_code == 200
    assert response.json()["status"] == "inactive"

    # History is preserved, not erased.
    db_session.refresh(case)
    assert db_session.query(models.Case).filter(models.Case.id == case.id).first() is not None


def test_patient_cannot_deactivate(client, db_session):
    patient = _user(db_session, "patient@example.com", models.UserRole.patient)

    response = client.delete(f"/patients/{patient.id}", headers=_headers(patient))

    assert response.status_code == 403


# --- POST /patients/{patient_id}/reactivate ---


def test_clinician_reactivates_patient(client, db_session):
    clinician = _user(db_session, "clinician@example.com", models.UserRole.clinician)
    patient = _user(db_session, "patient@example.com", models.UserRole.patient, status="inactive")

    response = client.post(f"/patients/{patient.id}/reactivate", headers=_headers(clinician))

    assert response.status_code == 200
    assert response.json()["status"] == "active"


# --- PATCH /cases/{case_id} ---


def test_owner_clinician_updates_case(client, db_session):
    clinician = _user(db_session, "clinician@example.com", models.UserRole.clinician)
    patient = _user(db_session, "patient@example.com", models.UserRole.patient)
    case = _case(db_session, clinician, patient, surgery_type="hip")

    response = client.patch(
        f"/cases/{case.id}",
        json={"surgery_type": "revised hip", "emergency_contact_phone": "+1-555-0199"},
        headers=_headers(clinician),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["surgery_type"] == "revised hip"
    assert body["emergency_contact_phone"] == "+1-555-0199"


def test_non_owner_clinician_cannot_update_case(client, db_session):
    clinician = _user(db_session, "clinician@example.com", models.UserRole.clinician)
    other_clinician = _user(db_session, "other-clinician@example.com", models.UserRole.clinician)
    patient = _user(db_session, "patient@example.com", models.UserRole.patient)
    case = _case(db_session, clinician, patient)

    response = client.patch(
        f"/cases/{case.id}",
        json={"surgery_type": "hijacked"},
        headers=_headers(other_clinician),
    )

    assert response.status_code == 404
