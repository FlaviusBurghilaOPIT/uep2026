from datetime import time
from app import models
from app.security import create_access_token
from app.services.schedule_parser import times_for_frequency, parse_duration_days


def test_times_for_frequency_all_codes():
    assert times_for_frequency("QD")  == [time(8, 0)]
    assert times_for_frequency("BID") == [time(8, 0), time(20, 0)]
    assert times_for_frequency("TID") == [time(8, 0), time(13, 0), time(20, 0)]
    assert times_for_frequency("QID") == [time(8, 0), time(12, 0), time(16, 0), time(20, 0)]
    assert times_for_frequency("PRN") == []


def test_times_for_frequency_case_insensitive():
    assert times_for_frequency("tid") == [time(8, 0), time(13, 0), time(20, 0)]
    assert times_for_frequency("Bid") == [time(8, 0), time(20, 0)]


def test_times_for_frequency_unknown_defaults_to_qd():
    assert times_for_frequency("UNKNOWN") == [time(8, 0)]


def test_parse_duration_days_variations():
    assert parse_duration_days("7 days") == 7
    assert parse_duration_days("10 days") == 10
    assert parse_duration_days("2 weeks") == 14
    assert parse_duration_days("1 week") == 7
    assert parse_duration_days("5") == 5
    assert parse_duration_days(None) == 7
    assert parse_duration_days("") == 7
    assert parse_duration_days("until finished") == 7


def _make_clinician_patient_case(db_session, suffix=""):
    clinician = models.User(
        email=f"doctor{suffix}@example.com",
        full_name=f"Dr. House{suffix}",
        role=models.UserRole.clinician,
    )
    patient = models.User(
        email=f"patient{suffix}@example.com",
        full_name=f"Patient{suffix}",
        role=models.UserRole.patient,
    )
    db_session.add_all([clinician, patient])
    db_session.commit()
    case = models.Case(
        clinician_id=clinician.id,
        patient_id=patient.id,
        surgery_type="ACL Repair",
    )
    db_session.add(case)
    db_session.commit()
    token = create_access_token(
        {"sub": clinician.id, "role": "clinician", "email": clinician.email}
    )
    return clinician, patient, case, token


def test_create_medication_tid_7days_generates_21_reminders(client, db_session):
    _, _, case, token = _make_clinician_patient_case(db_session, "1")
    payload = {
        "name": "Ibuprofen",
        "dose": "400mg",
        "frequency": "TID",
        "duration": "7 days",
        "notes": "Take with food",
    }
    response = client.post(
        f"/cases/{case.id}/medications",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    med_data = response.json()
    assert med_data["name"] == "Ibuprofen"
    assert med_data["frequency"] == "TID"
    assert med_data["schedule_times"] == ["08:00", "13:00", "20:00"]
    assert len(med_data["scheduled_reminders"]) == 21
    assert med_data["scheduled_reminders"][0]["status"] == "pending"
    assert "08:00:00" in med_data["scheduled_reminders"][0]["scheduled_time"]


def test_create_medication_bid_2weeks_generates_28_reminders(client, db_session):
    _, _, case, token = _make_clinician_patient_case(db_session, "2")
    payload = {
        "name": "Paracetamol",
        "dose": "500mg",
        "frequency": "BID",
        "duration": "2 weeks",
    }
    response = client.post(
        f"/cases/{case.id}/medications",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    med_data = response.json()
    assert len(med_data["scheduled_reminders"]) == 28
    assert med_data["schedule_times"] == ["08:00", "20:00"]


def test_create_medication_prn_generates_zero_reminders(client, db_session):
    _, _, case, token = _make_clinician_patient_case(db_session, "3")
    payload = {
        "name": "Tramadol",
        "dose": "50mg",
        "frequency": "PRN",
        "duration": "7 days",
    }
    response = client.post(
        f"/cases/{case.id}/medications",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    med_data = response.json()
    assert med_data["scheduled_reminders"] == []
    assert med_data["schedule_times"] == []


def test_create_medication_invalid_frequency_rejected(client, db_session):
    _, _, case, token = _make_clinician_patient_case(db_session, "4")
    payload = {
        "name": "Aspirin",
        "dose": "100mg",
        "frequency": "3x daily",   # invalid — must be enum code
        "duration": "7 days",
    }
    response = client.post(
        f"/cases/{case.id}/medications",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 422   # Pydantic validation error
