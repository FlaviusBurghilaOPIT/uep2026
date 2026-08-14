from app import models
from app.security import hash_password


def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_patient_invite_and_onboarding_flow(client, db_session):
    # 0. Create clinician in DB
    clinician = models.User(
        email="clinician@example.com",
        full_name="Dr. Smith",
        role=models.UserRole.clinician,
        password_hash=hash_password("password123"),
        status="active",
    )
    db_session.add(clinician)
    db_session.commit()

    # 1. Clinician login
    login_resp = client.post(
        "/auth/login",
        json={"email": "clinician@example.com", "password": "password123"},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Clinician invites patient
    invite_resp = client.post(
        "/patients/invite",
        headers=headers,
        json={
            "email": "invited_patient@example.com",
            "full_name": "John Doe",
            "surgery_type": "Knee Replacement",
            "date_of_birth": "1985-05-15",
            "surgery_date": "2025-06-18",
            "emergency_contact_phone": "+123456789",
        },
    )
    assert invite_resp.status_code == 200
    invite_data = invite_resp.json()
    assert "invite_code" in invite_data
    code = invite_data["invite_code"]

    # 3. Patient verifies invite
    verify_resp = client.post(
        "/auth/verify-invite",
        json={"email": "invited_patient@example.com", "invite_code": code},
    )
    assert verify_resp.status_code == 200
    assert verify_resp.json()["full_name"] == "John Doe"

    # 4. Patient completes onboarding
    complete_resp = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "invited_patient@example.com",
            "invite_code": code,
            "password": "newpassword123",
            "date_of_birth": "1985-05-15",
            "phone": "+1987654321",
        },
    )
    assert complete_resp.status_code == 200
    assert "access_token" in complete_resp.json()
