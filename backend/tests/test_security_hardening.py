import contextlib
from unittest.mock import MagicMock, patch

import pytest
from app import models
from app.security import create_access_token, hash_password


def _user(db_session, email, role):
    user = models.User(
        email=email,
        full_name=email.split("@")[0],
        role=role,
        status="active",
        password_hash=hash_password("pw123456"),
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def _token(user):
    return create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})


def _headers(user):
    return {"Authorization": f"Bearer {_token(user)}"}


def _case(db_session, clinician, patient):
    case = models.Case(
        clinician_id=clinician.id,
        patient_id=patient.id,
        surgery_type="knee",
        status="active",
    )
    db_session.add(case)
    db_session.commit()
    db_session.refresh(case)
    return case


@pytest.fixture(autouse=True)
def _mock_session_local(monkeypatch, db_session):
    @contextlib.contextmanager
    def mock():
        yield db_session

    monkeypatch.setattr("app.routers.ai.SessionLocal", mock)


@pytest.fixture(autouse=True)
def _mock_rag(monkeypatch):
    async def mock_async_generator(*args, **kwargs):
        for c in ["Secure", " Response"]:
            yield c

    monkeypatch.setattr("app.routers.ai.generate_recommendation_stream", mock_async_generator)


# 1. Gate POST /users/
def test_create_user_requires_clinician(client, db_session):
    patient = _user(db_session, "patient_reg@example.com", models.UserRole.patient)
    clinician = _user(db_session, "clinician_reg@example.com", models.UserRole.clinician)

    payload = {
        "email": "new_clinician@example.com",
        "full_name": "Dr. New",
        "password": "password123",
    }

    # Unauthenticated
    resp_anon = client.post("/users/", json=payload)
    assert resp_anon.status_code in (401, 403)

    # Patient cannot create clinician
    resp_patient = client.post("/users/", json=payload, headers=_headers(patient))
    assert resp_patient.status_code == 403

    # Clinician can create clinician
    resp_clinician = client.post("/users/", json=payload, headers=_headers(clinician))
    assert resp_clinician.status_code == 200
    assert resp_clinician.json()["email"] == "new_clinician@example.com"


# 2. AI Chat IDOR prevention
def test_ai_chat_idor_protection(client, db_session):
    clinician = _user(db_session, "c_idor@example.com", models.UserRole.clinician)
    other_clinician = _user(db_session, "c2_idor@example.com", models.UserRole.clinician)
    patient = _user(db_session, "p_idor@example.com", models.UserRole.patient)
    other_patient = _user(db_session, "p2_idor@example.com", models.UserRole.patient)
    case = _case(db_session, clinician, patient)

    req = {"case_id": case.id, "message": "Can I walk today?"}

    # Patient of the case can chat
    resp_owner_patient = client.post("/ai/chat", json=req, headers=_headers(patient))
    assert resp_owner_patient.status_code == 200

    # Another patient cannot chat on this case (IDOR prevented)
    resp_other_patient = client.post("/ai/chat", json=req, headers=_headers(other_patient))
    assert resp_other_patient.status_code == 404

    # Assigned clinician can chat
    resp_owner_clin = client.post("/ai/chat", json=req, headers=_headers(clinician))
    assert resp_owner_clin.status_code == 200

    # Non-assigned clinician cannot chat on this case
    resp_other_clin = client.post("/ai/chat", json=req, headers=_headers(other_clinician))
    assert resp_other_clin.status_code == 404


# 3. Patient Roster & UserResponse invite code leakage
def test_patient_roster_does_not_leak_invite_code_and_requires_clinician(client, db_session):
    clinician = _user(db_session, "c_roster@example.com", models.UserRole.clinician)
    patient = _user(db_session, "p_roster@example.com", models.UserRole.patient)
    patient.invite_code = "123456"
    db_session.commit()

    # Patient cannot list all patients
    resp_patient = client.get("/patients/", headers=_headers(patient))
    assert resp_patient.status_code == 403

    # Clinician lists patients — invite_code must NOT be present in response
    resp_clin = client.get("/patients/", headers=_headers(clinician))
    assert resp_clin.status_code == 200
    patients_data = resp_clin.json()
    assert len(patients_data) >= 1
    for p in patients_data:
        assert "invite_code" not in p

    # Single patient get — invite_code must NOT be present
    resp_get = client.get(f"/patients/{patient.id}", headers=_headers(clinician))
    assert resp_get.status_code == 200
    assert "invite_code" not in resp_get.json()


# 4. Patient single get authorization
def test_patient_cannot_view_other_patient_record(client, db_session):
    p1 = _user(db_session, "p1_iso@example.com", models.UserRole.patient)
    p2 = _user(db_session, "p2_iso@example.com", models.UserRole.patient)

    # Patient can view self
    resp_self = client.get(f"/patients/{p1.id}", headers=_headers(p1))
    assert resp_self.status_code == 200
    assert resp_self.json()["id"] == p1.id

    # Patient cannot view other patient
    resp_other = client.get(f"/patients/{p2.id}", headers=_headers(p1))
    assert resp_other.status_code == 404


# 5. Case creation requires clinician
def test_create_case_requires_clinician(client, db_session):
    patient = _user(db_session, "p_case_auth@example.com", models.UserRole.patient)
    payload = {"patient_id": patient.id, "surgery_type": "hip"}

    resp = client.post("/cases/", json=payload, headers=_headers(patient))
    assert resp.status_code == 403


# 6. /health/db failure reporting
def test_health_db_reports_503_on_failure(client):
    with patch("app.main.get_db") as mock_db:
        mock_session = MagicMock()
        mock_session.execute.side_effect = Exception("DB connection down")
        
        # Test endpoint directly
        from app.main import health_db
        with pytest.raises(Exception) as exc_info:
            health_db(db=mock_session)
        assert exc_info.value.status_code == 503
