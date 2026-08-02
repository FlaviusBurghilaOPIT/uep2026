from datetime import datetime, timedelta

from app import models
from app.security import create_access_token, verify_password


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


def test_complete_onboarding_without_password_leaves_password_hash_unset(client, db_session):
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


def test_complete_onboarding_with_expired_code_returns_400(client, db_session):
    _make_patient(db_session, status="pending_onboarding", expires_delta=timedelta(minutes=-1))

    response = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "date_of_birth": "1990-01-01",
            "phone": "1234567890",
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid email or invite code"

    patient = db_session.query(models.User).filter(models.User.email == "patient@example.com").first()
    assert patient.status == "pending_onboarding"


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
                "date_of_birth": "1990-01-01",
            },
            headers={"Authorization": f"Bearer {token}"},
        )

    assert response.status_code == 200
    invite_code = response.json()["invite_code"]
    mock_send.assert_called_once_with("newpatient@example.com", invite_code)

    patient = db_session.query(models.User).filter(models.User.email == "newpatient@example.com").first()
    assert patient.invite_code_expires_at is not None


# --- WI 01: Hybrid patient auth (password at onboarding, login, change-password) ---


def _patient_token(patient):
    return create_access_token(
        {"sub": patient.id, "role": patient.role.value, "email": patient.email}
    )


def test_complete_onboarding_with_password_stores_password_hash(client, db_session):
    _make_patient(db_session, status="pending_onboarding")

    response = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "date_of_birth": "1990-01-01",
            "phone": "1234567890",
            "password": "supersecret",
        },
    )

    assert response.status_code == 200
    patient = (
        db_session.query(models.User).filter(models.User.email == "patient@example.com").first()
    )
    assert patient.password_hash is not None
    assert verify_password("supersecret", patient.password_hash)
    assert patient.status == "active"


def test_login_for_patient_with_password_succeeds(client, db_session):
    _make_patient(db_session, status="pending_onboarding")

    onboarding = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "date_of_birth": "1990-01-01",
            "phone": "1234567890",
            "password": "supersecret",
        },
    )
    assert onboarding.status_code == 200

    ok = client.post(
        "/auth/login", json={"email": "patient@example.com", "password": "supersecret"}
    )
    assert ok.status_code == 200
    assert "access_token" in ok.json()

    bad = client.post(
        "/auth/login", json={"email": "patient@example.com", "password": "wrong-password"}
    )
    assert bad.status_code == 401


def test_change_password_for_code_authenticated_user_without_existing_password(client, db_session):
    patient = _make_patient(db_session, status="active")
    patient.invite_code = None
    patient.invite_code_expires_at = None
    assert patient.password_hash is None
    db_session.commit()

    token = _patient_token(patient)
    response = client.post(
        "/auth/change-password",
        json={"new_password": "brandnewpassword"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    db_session.refresh(patient)
    assert patient.password_hash is not None
    assert verify_password("brandnewpassword", patient.password_hash)


def test_change_password_requires_current_password_when_one_exists(client, db_session):
    patient = _make_patient(db_session, status="active")
    patient.invite_code = None
    patient.invite_code_expires_at = None
    db_session.commit()

    # Seed an existing password via the authenticated endpoint (no current needed yet).
    token = _patient_token(patient)
    seeded = client.post(
        "/auth/change-password",
        json={"new_password": "originalpassword"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert seeded.status_code == 200
    db_session.refresh(patient)
    assert verify_password("originalpassword", patient.password_hash)

    # Missing current password -> rejected.
    missing = client.post(
        "/auth/change-password",
        json={"new_password": "anotherpassword"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert missing.status_code == 400

    # Wrong current password -> rejected and password unchanged.
    wrong = client.post(
        "/auth/change-password",
        json={"current_password": "not-the-right-one", "new_password": "anotherpassword"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert wrong.status_code == 400
    db_session.refresh(patient)
    assert verify_password("originalpassword", patient.password_hash)

    # Correct current password -> updated.
    ok = client.post(
        "/auth/change-password",
        json={"current_password": "originalpassword", "new_password": "anotherpassword"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert ok.status_code == 200
    db_session.refresh(patient)
    assert verify_password("anotherpassword", patient.password_hash)
    assert not verify_password("originalpassword", patient.password_hash)


def test_change_password_requires_authentication(client, db_session):
    _make_patient(db_session, status="active")

    response = client.post("/auth/change-password", json={"new_password": "brandnewpassword"})
    assert response.status_code in (401, 403)


def test_complete_onboarding_date_of_birth_is_optional_but_updatable(client, db_session):
    # Omitted -> existing DOB (pre-set at intake) is preserved.
    patient = _make_patient(db_session, status="pending_onboarding")
    patient.date_of_birth = "1980-01-01"
    db_session.commit()

    omitted = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "phone": "1234567890",
        },
    )
    assert omitted.status_code == 200
    db_session.refresh(patient)
    assert patient.date_of_birth == "1980-01-01"
    assert patient.phone == "1234567890"
    assert patient.status == "active"


def test_complete_onboarding_date_of_birth_updates_when_supplied(client, db_session):
    patient = _make_patient(db_session, status="pending_onboarding")
    patient.date_of_birth = "1980-01-01"
    db_session.commit()

    supplied = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "date_of_birth": "1995-05-05",
            "phone": "1234567890",
        },
    )
    assert supplied.status_code == 200
    db_session.refresh(patient)
    assert patient.date_of_birth == "1995-05-05"


# --- WI 04 gap closure: DOB pre-fill + persist name edits (Req 9) ---


def test_verify_code_onboarding_response_includes_date_of_birth(client, db_session):
    patient = _make_patient(db_session, status="pending_onboarding")
    patient.date_of_birth = "1988-04-12"
    db_session.commit()

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "111111"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["result"] == "onboarding"
    assert body["date_of_birth"] == "1988-04-12"


def test_verify_code_onboarding_response_date_of_birth_null_when_unset(client, db_session):
    _make_patient(db_session, status="pending_onboarding")  # no DOB at intake

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "111111"},
    )

    assert response.status_code == 200
    assert response.json()["date_of_birth"] is None


def test_complete_onboarding_persists_full_name_when_supplied(client, db_session):
    _make_patient(db_session, status="pending_onboarding")  # full_name="Jane Doe"

    response = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "full_name": "Jane Smith",
            "phone": "1234567890",
        },
    )

    assert response.status_code == 200
    patient = (
        db_session.query(models.User).filter(models.User.email == "patient@example.com").first()
    )
    assert patient.full_name == "Jane Smith"
    assert patient.status == "active"


def test_complete_onboarding_preserves_full_name_when_omitted(client, db_session):
    _make_patient(db_session, status="pending_onboarding")  # full_name="Jane Doe"

    response = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "phone": "1234567890",
        },
    )

    assert response.status_code == 200
    patient = (
        db_session.query(models.User).filter(models.User.email == "patient@example.com").first()
    )
    assert patient.full_name == "Jane Doe"


# --- WI 06: Profile update (PATCH /auth/me) + has_password on GET /auth/me ---


def _active_patient(db_session):
    patient = _make_patient(db_session, status="active")
    patient.invite_code = None
    patient.invite_code_expires_at = None
    db_session.commit()
    return patient


def test_get_me_reports_has_password_false_for_code_only_patient(client, db_session):
    patient = _active_patient(db_session)
    assert patient.password_hash is None

    response = client.get(
        "/auth/me", headers={"Authorization": f"Bearer {_patient_token(patient)}"}
    )

    assert response.status_code == 200
    assert response.json()["has_password"] is False


def test_get_me_reports_has_password_true_after_password_set(client, db_session):
    patient = _active_patient(db_session)
    token = _patient_token(patient)
    seeded = client.post(
        "/auth/change-password",
        json={"new_password": "brandnewpassword"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert seeded.status_code == 200

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert response.json()["has_password"] is True


def test_patch_me_updates_only_supplied_fields_and_round_trips(client, db_session):
    patient = _active_patient(db_session)  # full_name="Jane Doe", phone=None
    token = _patient_token(patient)

    response = client.patch(
        "/auth/me",
        json={"phone": "+39 333 1234567"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["phone"] == "+39 333 1234567"
    # Untouched fields are preserved.
    assert body["full_name"] == "Jane Doe"

    # Persists and round-trips via GET /auth/me.
    refreshed = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert refreshed.status_code == 200
    assert refreshed.json()["phone"] == "+39 333 1234567"
    assert refreshed.json()["full_name"] == "Jane Doe"

    db_session.refresh(patient)
    assert patient.phone == "+39 333 1234567"
    assert patient.full_name == "Jane Doe"


def test_patch_me_updates_full_name_and_date_of_birth(client, db_session):
    patient = _active_patient(db_session)
    token = _patient_token(patient)

    response = client.patch(
        "/auth/me",
        json={"full_name": "Jane Smith", "date_of_birth": "1988-03-14"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    db_session.refresh(patient)
    assert patient.full_name == "Jane Smith"
    assert patient.date_of_birth == "1988-03-14"


def test_patch_me_requires_authentication(client, db_session):
    response = client.patch("/auth/me", json={"phone": "123"})

    assert response.status_code in (401, 403)
