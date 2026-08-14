from app import models
from app.security import create_access_token, hash_password


def _make_user(db_session, *, email, name, role, status="active"):
    user = models.User(
        email=email,
        full_name=name,
        role=role,
        status=status,
        password_hash=hash_password("pw"),
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def _auth_headers(user):
    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"Authorization": f"Bearer {token}"}


def test_triage_roster_excludes_non_patients_and_paginates(client, db_session):
    clinician = _make_user(
        db_session, email="clin@t.com", name="Clin", role=models.UserRole.clinician
    )
    _make_user(db_session, email="alice@t.com", name="Alice Smith", role=models.UserRole.patient)
    _make_user(db_session, email="bob@t.com", name="Bob Jones", role=models.UserRole.patient)
    _make_user(db_session, email="carol@t.com", name="Carol Smith", role=models.UserRole.patient)

    resp = client.get("/patients/triage?size=2&page=1", headers=_auth_headers(clinician))
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 3  # clinician excluded
    assert body["page"] == 1
    assert body["size"] == 2
    assert len(body["items"]) == 2
    assert all(p["role"] == "patient" for p in body["items"])


def test_triage_roster_qbe_matches_name_and_email(client, db_session):
    clinician = _make_user(
        db_session, email="clin@t.com", name="Clin", role=models.UserRole.clinician
    )
    _make_user(db_session, email="alice@t.com", name="Alice Smith", role=models.UserRole.patient)
    _make_user(db_session, email="bob@t.com", name="Bob Jones", role=models.UserRole.patient)
    _make_user(db_session, email="carol@t.com", name="Carol Smith", role=models.UserRole.patient)

    # Partial, case-insensitive name match.
    resp = client.get("/patients/triage?search=smith", headers=_auth_headers(clinician))
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 2
    assert {p["full_name"] for p in body["items"]} == {"Alice Smith", "Carol Smith"}

    # Email match.
    resp = client.get("/patients/triage?search=bob@", headers=_auth_headers(clinician))
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 1
    assert body["items"][0]["email"] == "bob@t.com"


def test_triage_roster_qbe_matches_surgery_type_via_case(client, db_session):
    clinician = _make_user(
        db_session, email="clin@t.com", name="Clin", role=models.UserRole.clinician
    )
    patient = _make_user(
        db_session, email="alice@t.com", name="Alice", role=models.UserRole.patient
    )
    db_session.add(
        models.Case(
            clinician_id=clinician.id,
            patient_id=patient.id,
            surgery_type="Knee Replacement",
            status="active",
        )
    )
    db_session.commit()

    resp = client.get("/patients/triage?search=knee", headers=_auth_headers(clinician))
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 1
    assert body["items"][0]["id"] == patient.id


def test_triage_roster_requires_clinician(client, db_session):
    patient = _make_user(
        db_session, email="pat@t.com", name="Pat", role=models.UserRole.patient
    )
    resp = client.get("/patients/triage", headers=_auth_headers(patient))
    assert resp.status_code == 403
