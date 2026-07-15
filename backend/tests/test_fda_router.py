from app import models
from app.security import create_access_token, hash_password


def _make_clinician(db_session):
    clinician = models.User(
        email="clin@t.com",
        full_name="Clin",
        role=models.UserRole.clinician,
        password_hash=hash_password("pw"),
    )
    db_session.add(clinician)
    db_session.commit()
    db_session.refresh(clinician)
    return clinician


def _auth_headers(user):
    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"Authorization": f"Bearer {token}"}


def _make_patient(db_session):
    patient = models.User(
        email="patient@t.com",
        full_name="Pat",
        role=models.UserRole.patient,
        password_hash=hash_password("pw"),
    )
    db_session.add(patient)
    db_session.commit()
    db_session.refresh(patient)
    return patient


def test_patient_cannot_list_warnings(client, db_session):
    patient = _make_patient(db_session)

    response = client.get("/fda/warnings", headers=_auth_headers(patient))

    assert response.status_code == 403


def test_patient_cannot_approve_warning(client, db_session):
    patient = _make_patient(db_session)
    warning = models.FDAWarning(drug_name="ibuprofen", summary="s", severity="moderate")
    db_session.add(warning)
    db_session.commit()
    db_session.refresh(warning)

    response = client.post(f"/fda/warnings/{warning.id}/approve", headers=_auth_headers(patient))

    assert response.status_code == 403


def test_warnings_queue_lists_pending_only(client, db_session):
    clinician = _make_clinician(db_session)
    pending = models.FDAWarning(drug_name="ibuprofen", summary="s", severity="moderate")
    approved = models.FDAWarning(
        drug_name="aspirin",
        summary="s",
        severity="low",
        status=models.FDAWarningStatus.approved,
    )
    db_session.add_all([pending, approved])
    db_session.commit()

    response = client.get("/fda/warnings", headers=_auth_headers(clinician))

    assert response.status_code == 200
    drugs = [w["drug_name"] for w in response.json()]
    assert drugs == ["ibuprofen"]


def test_approve_propagates_to_active_cases_with_matching_drug(client, db_session):
    clinician = _make_clinician(db_session)
    patient = models.User(email="pat@t.com", full_name="Pat", role=models.UserRole.patient)
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

    med = models.Medication(
        case_id=case.id,
        name="Ibuprofen",
        dose="200mg",
        schedule_text="daily",
        duration="7 days",
    )
    warning = models.FDAWarning(drug_name="ibuprofen", summary="s", severity="moderate")
    db_session.add_all([med, warning])
    db_session.commit()
    db_session.refresh(warning)

    response = client.post(f"/fda/warnings/{warning.id}/approve", headers=_auth_headers(clinician))

    assert response.status_code == 200
    links = db_session.query(models.CaseFDAWarning).filter_by(case_id=case.id).all()
    assert len(links) == 1

    db_session.refresh(warning)
    assert warning.status == models.FDAWarningStatus.approved
    assert warning.reviewed_by == clinician.id


def test_dismiss_does_not_propagate(client, db_session):
    clinician = _make_clinician(db_session)
    warning = models.FDAWarning(drug_name="ibuprofen", summary="s", severity="moderate")
    db_session.add(warning)
    db_session.commit()
    db_session.refresh(warning)

    response = client.post(f"/fda/warnings/{warning.id}/dismiss", headers=_auth_headers(clinician))

    assert response.status_code == 200
    db_session.refresh(warning)
    assert warning.status == models.FDAWarningStatus.dismissed
    assert db_session.query(models.CaseFDAWarning).count() == 0


def test_approve_does_not_duplicate_case_link_for_multiple_matching_medications(client, db_session):
    clinician = _make_clinician(db_session)
    patient = models.User(email="pat2@t.com", full_name="Pat", role=models.UserRole.patient)
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

    med1 = models.Medication(
        case_id=case.id,
        name="Ibuprofen",
        dose="200mg",
        schedule_text="daily",
        duration="7 days",
    )
    med2 = models.Medication(
        case_id=case.id,
        name="Ibuprofen",
        dose="400mg",
        schedule_text="as needed",
        duration="7 days",
    )
    warning = models.FDAWarning(drug_name="ibuprofen", summary="s", severity="moderate")
    db_session.add_all([med1, med2, warning])
    db_session.commit()
    db_session.refresh(warning)

    response = client.post(f"/fda/warnings/{warning.id}/approve", headers=_auth_headers(clinician))

    assert response.status_code == 200
    links = db_session.query(models.CaseFDAWarning).filter_by(case_id=case.id).all()
    assert len(links) == 1


def test_drug_info_returns_llm_summary_with_source(client, db_session, monkeypatch):
    monkeypatch.setenv("FDA_PROVIDER", "fixture")
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    clinician = _make_clinician(db_session)

    response = client.get("/fda/drug/aspirin", headers=_auth_headers(clinician))

    assert response.status_code == 200
    body = response.json()
    assert body["drug_name"] == "aspirin"
    assert body["summary"] == "This is a mock AI response. The real AI will answer here."
    assert body["source"] == "fixture"
