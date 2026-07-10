from app import models
from app.security import create_access_token


def test_create_case_defaults_emergency_contact_to_clinician(client, db_session):
    clinician = models.User(
        email="c@t.com",
        full_name="Dr. Clinician",
        role=models.UserRole.clinician,
    )
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    token = create_access_token(
        {"sub": clinician.id, "role": "clinician", "email": clinician.email}
    )
    response = client.post(
        "/cases/",
        json={"patient_id": patient.id, "surgery_type": "knee"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["emergency_contact_name"] == "Dr. Clinician"


def test_emergency_contact_endpoint_returns_name_and_phone(client, db_session):
    clinician = models.User(
        email="c@t.com",
        full_name="Dr. Clinician",
        role=models.UserRole.clinician,
    )
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(
        clinician_id=clinician.id,
        patient_id=patient.id,
        surgery_type="knee",
        emergency_contact_name="Dr. Clinician",
        emergency_contact_phone="+1-555-0100",
    )
    db_session.add(case)
    db_session.commit()
    db_session.refresh(case)

    token = create_access_token({"sub": patient.id, "role": "patient", "email": patient.email})
    response = client.get(
        f"/cases/{case.id}/emergency-contact",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json() == {"name": "Dr. Clinician", "phone": "+1-555-0100"}
