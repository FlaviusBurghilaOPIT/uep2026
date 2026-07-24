from datetime import datetime, timedelta

from app import models


def _make_patient(db_session, status="pending_onboarding", code="111111", expires_delta=timedelta(minutes=15)):
    patient = models.User(
        email="patient@example.com",
        full_name="Jane Doe",
        role=models.UserRole.patient,
        status=status,
        invite_code=code,
        invite_code_expires_at=datetime.utcnow() + expires_delta,
    )
    db_session.add(patient)
    db_session.commit()
    db_session.refresh(patient)
    return patient


def test_request_code_for_unknown_email_returns_generic_200_and_creates_no_user(client, db_session):
    response = client.post("/auth/patient/request-code", json={"email": "nobody@example.com"})

    assert response.status_code == 200
    assert response.json() == {"message": "If that email exists, a code was sent."}
    assert db_session.query(models.User).filter(models.User.email == "nobody@example.com").first() is None


def test_request_code_for_existing_patient_sets_code_and_expiry(client, db_session):
    patient = _make_patient(db_session)
    patient.invite_code = None
    patient.invite_code_expires_at = None
    db_session.commit()

    response = client.post("/auth/patient/request-code", json={"email": "patient@example.com"})

    assert response.status_code == 200
    db_session.refresh(patient)
    assert patient.invite_code is not None
    assert len(patient.invite_code) == 6
    assert patient.invite_code_expires_at is not None
    assert patient.invite_code_expires_at > datetime.utcnow()


def test_verify_code_with_expired_code_returns_400(client, db_session):
    _make_patient(db_session, expires_delta=timedelta(minutes=-1))

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "111111"},
    )

    assert response.status_code == 400


def test_verify_code_with_wrong_code_returns_400(client, db_session):
    _make_patient(db_session)

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "999999"},
    )

    assert response.status_code == 400


def test_verify_code_for_pending_onboarding_user_returns_onboarding_result(client, db_session):
    _make_patient(db_session, status="pending_onboarding")

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "111111"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["result"] == "onboarding"
    assert body["email"] == "patient@example.com"
    assert body["full_name"] == "Jane Doe"
    assert "access_token" not in body


def test_verify_code_for_active_user_returns_token_and_clears_code(client, db_session):
    patient = _make_patient(db_session, status="active")

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "111111"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["result"] == "authenticated"
    assert "access_token" in body

    db_session.refresh(patient)
    assert patient.invite_code is None
    assert patient.invite_code_expires_at is None


def test_complete_onboarding_does_not_accept_or_persist_password(client, db_session):
    _make_patient(db_session, status="pending_onboarding")

    response = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "date_of_birth": "1990-01-01",
            "phone": "1234567890",
        },
    )

    assert response.status_code == 200
    patient = db_session.query(models.User).filter(models.User.email == "patient@example.com").first()
    assert patient.password_hash is None
    assert patient.status == "active"


from unittest.mock import patch


def test_invite_patient_sends_code_via_email(client, db_session):
    clinician = models.User(
        email="c@t.com",
        full_name="Dr. Clinician",
        role=models.UserRole.clinician,
    )
    db_session.add(clinician)
    db_session.commit()

    from app.security import create_access_token

    token = create_access_token({"sub": clinician.id, "role": "clinician", "email": clinician.email})

    with patch("app.routers.patients.EmailService.send_patient_code") as mock_send:
        response = client.post(
            "/patients/invite",
            json={
                "email": "newpatient@example.com",
                "full_name": "New Patient",
                "surgery_type": "knee",
            },
            headers={"Authorization": f"Bearer {token}"},
        )

    assert response.status_code == 200
    invite_code = response.json()["invite_code"]
    mock_send.assert_called_once_with("newpatient@example.com", invite_code)

    patient = db_session.query(models.User).filter(models.User.email == "newpatient@example.com").first()
    assert patient.invite_code_expires_at is not None
