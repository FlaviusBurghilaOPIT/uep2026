from app import models
from app.security import create_access_token, hash_password


def _auth_headers(user):
    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"Authorization": f"Bearer {token}"}


def _make_case_with_meds(db_session):
    clinician = models.User(
        email="c@t.com",
        full_name="C",
        role=models.UserRole.clinician,
        password_hash=hash_password("pw"),
    )
    patient = models.User(
        email="p@t.com",
        full_name="P",
        role=models.UserRole.patient,
        password_hash=hash_password("pw"),
    )
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db_session.add(case)
    db_session.commit()

    med = models.Medication(
        case_id=case.id,
        name="Ibuprofen",
        dose="200mg",
        schedule_text="twice daily",
        duration="7 days",
    )
    db_session.add(med)
    db_session.commit()

    return patient, case


def test_chat_persists_both_turns(client, db_session, monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    response = client.post(
        "/ai/chat",
        json={"case_id": case.id, "message": "How should I take my ibuprofen?"},
        headers=_auth_headers(patient),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["in_scope"] is True
    assert body["escalate"] is False

    messages = db_session.query(models.ChatMessage).filter_by(case_id=case.id).all()
    assert len(messages) == 2
    assert messages[0].role == models.ChatRole.user
    assert messages[1].role == models.ChatRole.assistant
    assert messages[0].in_scope is True
    assert messages[0].escalate is False


def test_chat_flags_dosage_change_language_as_out_of_scope(client, db_session, monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    response = client.post(
        "/ai/chat",
        json={"case_id": case.id, "message": "Should I take a double dose today?"},
        headers=_auth_headers(patient),
    )

    body = response.json()
    assert body["in_scope"] is False
    assert body["escalate"] is True

    user_message = (
        db_session.query(models.ChatMessage)
        .filter_by(case_id=case.id, role=models.ChatRole.user)
        .first()
    )
    assert user_message.in_scope is False
    assert user_message.escalate is True
