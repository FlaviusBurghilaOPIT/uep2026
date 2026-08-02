"""Final review (0002): authorization on GET /patients/{patient_id}/case and
GET /cases/{case_id}/recommendations.

Rule: a patient may read only their own case; a clinician only cases they own.
Unauthorized access returns 404 (indistinguishable from a missing resource),
matching the existing create_recommendation convention.
"""

from app import models
from app.security import create_access_token


def _user(db_session, email, role):
    user = models.User(
        email=email,
        full_name=email.split("@")[0],
        role=role,
        status="active",
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


def _setup(db_session):
    """Owner clinician + patient with a case, plus a non-owner clinician and
    a second patient."""
    clinician = _user(db_session, "clinician@example.com", models.UserRole.clinician)
    other_clinician = _user(db_session, "other-clinician@example.com", models.UserRole.clinician)
    patient = _user(db_session, "patient@example.com", models.UserRole.patient)
    other_patient = _user(db_session, "other-patient@example.com", models.UserRole.patient)
    case = _case(db_session, clinician, patient)
    return clinician, other_clinician, patient, other_patient, case


# --- GET /patients/{patient_id}/case ---


def test_patient_case_patient_reads_own_case(client, db_session):
    _, _, patient, _, case = _setup(db_session)

    response = client.get(f"/patients/{patient.id}/case", headers=_headers(patient))

    assert response.status_code == 200
    assert response.json()["id"] == case.id


def test_patient_case_patient_cannot_read_another_patients_case(client, db_session):
    _, _, patient, other_patient, _ = _setup(db_session)

    response = client.get(f"/patients/{patient.id}/case", headers=_headers(other_patient))

    assert response.status_code == 404


def test_patient_case_owner_clinician_reads(client, db_session):
    clinician, _, patient, _, case = _setup(db_session)

    response = client.get(f"/patients/{patient.id}/case", headers=_headers(clinician))

    assert response.status_code == 200
    assert response.json()["id"] == case.id


def test_patient_case_non_owner_clinician_gets_404(client, db_session):
    _, other_clinician, patient, _, _ = _setup(db_session)

    response = client.get(f"/patients/{patient.id}/case", headers=_headers(other_clinician))

    assert response.status_code == 404


def test_patient_case_requires_authentication(client, db_session):
    _, _, patient, _, _ = _setup(db_session)

    response = client.get(f"/patients/{patient.id}/case")

    assert response.status_code in (401, 403)


# --- GET /cases/{case_id}/recommendations ---


def _seed_recommendation(db_session, case):
    rec = models.Recommendation(case_id=case.id, text="Take it easy for 48 hours")
    db_session.add(rec)
    db_session.commit()
    return rec


def test_recommendations_patient_reads_own_case(client, db_session):
    _, _, patient, _, case = _setup(db_session)
    _seed_recommendation(db_session, case)

    response = client.get(f"/cases/{case.id}/recommendations", headers=_headers(patient))

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_recommendations_patient_cannot_read_another_patients_case(client, db_session):
    _, _, _, other_patient, case = _setup(db_session)
    _seed_recommendation(db_session, case)

    response = client.get(f"/cases/{case.id}/recommendations", headers=_headers(other_patient))

    assert response.status_code == 404


def test_recommendations_owner_clinician_reads(client, db_session):
    clinician, _, _, _, case = _setup(db_session)
    _seed_recommendation(db_session, case)

    response = client.get(f"/cases/{case.id}/recommendations", headers=_headers(clinician))

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_recommendations_non_owner_clinician_gets_404(client, db_session):
    _, other_clinician, _, _, case = _setup(db_session)
    _seed_recommendation(db_session, case)

    response = client.get(f"/cases/{case.id}/recommendations", headers=_headers(other_clinician))

    assert response.status_code == 404


def test_recommendations_requires_authentication(client, db_session):
    _, _, _, _, case = _setup(db_session)

    response = client.get(f"/cases/{case.id}/recommendations")

    assert response.status_code in (401, 403)
