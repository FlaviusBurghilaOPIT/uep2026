"""WI 02 — Intake data model: required DOB at invite, nullable Case.surgery_date,
and the patient-accessible case response exposing surgery_date + DOB."""

from unittest.mock import patch

from app import models
from app.security import create_access_token


def _make_clinician(db_session, email="clinician@example.com"):
    clinician = models.User(
        email=email,
        full_name="Dr. Clinician",
        role=models.UserRole.clinician,
    )
    db_session.add(clinician)
    db_session.commit()
    db_session.refresh(clinician)
    return clinician


def _token(user):
    return create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})


def test_invite_patient_requires_date_of_birth(client, db_session):
    clinician = _make_clinician(db_session)
    headers = {"Authorization": f"Bearer {_token(clinician)}"}

    response = client.post(
        "/patients/invite",
        json={
            "email": "newpatient@example.com",
            "full_name": "New Patient",
            "surgery_type": "knee",
        },
        headers=headers,
    )

    assert response.status_code == 422
    assert (
        db_session.query(models.User).filter(models.User.email == "newpatient@example.com").first()
        is None
    )


def test_invite_patient_stores_date_of_birth_and_surgery_date(client, db_session):
    clinician = _make_clinician(db_session)
    headers = {"Authorization": f"Bearer {_token(clinician)}"}

    with patch("app.routers.patients.EmailService.send_patient_code"):
        response = client.post(
            "/patients/invite",
            json={
                "email": "newpatient@example.com",
                "full_name": "New Patient",
                "surgery_type": "knee",
                "date_of_birth": "1988-03-14",
                "surgery_date": "2025-06-18",
            },
            headers=headers,
        )

    assert response.status_code == 200
    patient_id = response.json()["patient_id"]

    patient = db_session.query(models.User).filter(models.User.id == patient_id).first()
    assert patient.date_of_birth == "1988-03-14"

    case = db_session.query(models.Case).filter(models.Case.patient_id == patient_id).first()
    assert case is not None
    assert case.surgery_date == "2025-06-18"


def test_invite_patient_without_surgery_date_leaves_case_surgery_date_null(client, db_session):
    clinician = _make_clinician(db_session)
    headers = {"Authorization": f"Bearer {_token(clinician)}"}

    with patch("app.routers.patients.EmailService.send_patient_code"):
        response = client.post(
            "/patients/invite",
            json={
                "email": "newpatient@example.com",
                "full_name": "New Patient",
                "surgery_type": "knee",
                "date_of_birth": "1988-03-14",
            },
            headers=headers,
        )

    assert response.status_code == 200
    patient_id = response.json()["patient_id"]
    case = db_session.query(models.Case).filter(models.Case.patient_id == patient_id).first()
    assert case.surgery_date is None


def test_create_case_stores_surgery_date_when_provided(client, db_session):
    clinician = _make_clinician(db_session)
    patient = models.User(
        email="patient@example.com",
        full_name="Jane Doe",
        role=models.UserRole.patient,
        status="active",
    )
    db_session.add(patient)
    db_session.commit()
    db_session.refresh(patient)

    headers = {"Authorization": f"Bearer {_token(clinician)}"}
    response = client.post(
        "/cases/",
        json={"patient_id": patient.id, "surgery_type": "knee", "surgery_date": "2025-06-18"},
        headers=headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["surgery_date"] == "2025-06-18"

    case = db_session.query(models.Case).filter(models.Case.patient_id == patient.id).first()
    assert case.surgery_date == "2025-06-18"


def test_case_model_surgery_date_defaults_to_null(db_session):
    clinician = _make_clinician(db_session)
    patient = models.User(
        email="patient@example.com",
        full_name="Jane Doe",
        role=models.UserRole.patient,
        status="active",
    )
    db_session.add(patient)
    db_session.commit()

    case = models.Case(
        clinician_id=clinician.id,
        patient_id=patient.id,
        surgery_type="knee",
        status="active",
    )
    db_session.add(case)
    db_session.commit()
    db_session.refresh(case)

    assert case.surgery_date is None


def test_patient_case_response_exposes_surgery_date_and_dob(client, db_session):
    clinician = _make_clinician(db_session)
    patient = models.User(
        email="patient@example.com",
        full_name="Jane Doe",
        role=models.UserRole.patient,
        status="active",
        date_of_birth="1988-03-14",
    )
    db_session.add(patient)
    db_session.commit()
    db_session.refresh(patient)

    case = models.Case(
        clinician_id=clinician.id,
        patient_id=patient.id,
        surgery_type="knee",
        surgery_date="2025-06-18",
        status="active",
    )
    db_session.add(case)
    db_session.commit()

    headers = {"Authorization": f"Bearer {_token(clinician)}"}
    response = client.get(f"/patients/{patient.id}/case", headers=headers)

    assert response.status_code == 200
    body = response.json()
    assert body["surgery_date"] == "2025-06-18"
    assert body["patient_date_of_birth"] == "1988-03-14"
