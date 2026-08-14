import json
import pytest
from app import models
from app.security import create_access_token
from app.services.sns_push_service import SNSPushService


def _clinician_headers(db_session):
    clinician = models.User(
        email="clinician-notif@example.com",
        full_name="Dr. Notif",
        role=models.UserRole.clinician,
    )
    db_session.add(clinician)
    db_session.commit()
    db_session.refresh(clinician)
    token = create_access_token(
        {"sub": clinician.id, "role": "clinician", "email": clinician.email}
    )
    return clinician, {"Authorization": f"Bearer {token}"}


def _patient_headers(db_session):
    patient = models.User(
        email="patient-notif@example.com",
        full_name="Pat Notif",
        role=models.UserRole.patient,
    )
    db_session.add(patient)
    db_session.commit()
    db_session.refresh(patient)
    token = create_access_token(
        {"sub": patient.id, "role": "patient", "email": patient.email}
    )
    return patient, {"Authorization": f"Bearer {token}"}


def test_register_device_token_patient(client, db_session):
    patient, headers = _patient_headers(db_session)

    response = client.post(
        "/notifications/register-token",
        json={"token": "sample-apns-token-999", "platform": "ios"},
        headers=headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == patient.id
    assert data["token"] == "sample-apns-token-999"
    assert data["platform"] == "ios"
    assert data["is_active"] is True
    assert isinstance(data["id"], int)


def test_register_device_token_update_existing(client, db_session):
    patient, headers = _patient_headers(db_session)

    client.post(
        "/notifications/register-token",
        json={"token": "unique-token-abc", "platform": "ios"},
        headers=headers,
    )

    # Register same token with updated platform
    response = client.post(
        "/notifications/register-token",
        json={"token": "unique-token-abc", "platform": "android"},
        headers=headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["platform"] == "android"

    # Ensure single DB record exists
    tokens = (
        db_session.query(models.DeviceToken)
        .filter(models.DeviceToken.token == "unique-token-abc")
        .all()
    )
    assert len(tokens) == 1
    assert tokens[0].platform == "android"


def test_send_test_push_as_clinician_dry_run(client, db_session):
    clinician, clin_headers = _clinician_headers(db_session)
    patient, pat_headers = _patient_headers(db_session)

    # Register token for patient
    client.post(
        "/notifications/register-token",
        json={"token": "pat-device-token-111", "platform": "ios"},
        headers=pat_headers,
    )

    # Clinician triggers test push
    response = client.post(
        "/notifications/send-test",
        json={
            "user_id": patient.id,
            "title": "Dose Reminder",
            "body": "Please take your evening dose.",
            "data_payload": {"reminder_id": "rem-123"},
        },
        headers=clin_headers,
    )

    assert response.status_code == 200
    res = response.json()
    assert res["sent"] == 1
    assert res["dry_run"] is True
    assert len(res["results"]) == 1
    item = res["results"][0]
    assert item["token"] == "pat-device-token-111"
    assert item["status"] == "dry_run_success"

    sns_msg = item["sns_message"]
    assert "default" in sns_msg
    assert "APNS" in sns_msg
    assert "APNS_SANDBOX" in sns_msg
    assert "GCM" in sns_msg
    assert "FCM" in sns_msg


def test_send_test_push_as_patient_forbidden(client, db_session):
    patient, pat_headers = _patient_headers(db_session)

    response = client.post(
        "/notifications/send-test",
        json={
            "user_id": patient.id,
            "title": "Test",
            "body": "Test body",
        },
        headers=pat_headers,
    )

    assert response.status_code == 403


def test_send_test_push_target_user_not_found(client, db_session):
    _, clin_headers = _clinician_headers(db_session)

    response = client.post(
        "/notifications/send-test",
        json={
            "user_id": "nonexistent-user-uuid",
            "title": "Test",
            "body": "Test body",
        },
        headers=clin_headers,
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Target user not found"


def test_send_test_push_no_active_tokens(client, db_session):
    _, clin_headers = _clinician_headers(db_session)
    patient, _ = _patient_headers(db_session)

    response = client.post(
        "/notifications/send-test",
        json={
            "user_id": patient.id,
            "title": "Test",
            "body": "Test body",
        },
        headers=clin_headers,
    )

    assert response.status_code == 200
    res = response.json()
    assert res["sent"] == 0
    assert res["status"] == "no_active_tokens"


def test_sns_push_service_direct_unit_tests(db_session):
    service = SNSPushService(db_session)
    assert service.dry_run is True

    # Test payload construction
    apns = service.build_apns_payload("Title", "Body", {"extra": "val"})
    apns_dict = json.loads(apns)
    assert apns_dict["aps"]["alert"]["title"] == "Title"
    assert apns_dict["aps"]["alert"]["body"] == "Body"
    assert apns_dict["extra"] == "val"

    fcm = service.build_fcm_payload("Title", "Body", {"extra": "val"})
    fcm_dict = json.loads(fcm)
    assert fcm_dict["notification"]["title"] == "Title"
    assert fcm_dict["data"]["extra"] == "val"

    sns_msg = service.build_sns_message("Title", "Body", {"extra": "val"})
    msg_dict = json.loads(sns_msg)
    assert "default" in msg_dict
    assert "APNS" in msg_dict
    assert "APNS_SANDBOX" in msg_dict
    assert "GCM" in msg_dict
    assert "FCM" in msg_dict
