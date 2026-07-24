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
        schedule_text="BID",   # now a code
        duration="7 days",
    )
    db_session.add(med)
    db_session.commit()

    return patient, case


def test_chat_general_question_is_in_scope(client, db_session, monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    response = client.post(
        "/ai/chat",
        json={
            "case_id": case.id,
            "message": "How should I take my ibuprofen?",
            "intent_category": "general_question",
        },
        headers=_auth_headers(patient),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["in_scope"] is True
    assert body["escalate"] is False

    messages = db_session.query(models.ChatMessage).filter_by(case_id=case.id).all()
    assert len(messages) == 2
    assert messages[0].in_scope is True
    assert messages[0].escalate is False


def test_chat_dose_change_intent_is_blocked(client, db_session, monkeypatch):
    """Guardrail blocks dose_change_request regardless of message language."""
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    response = client.post(
        "/ai/chat",
        json={
            "case_id": case.id,
            "message": "Posso raddoppiare la dose?",   # Italian — English regex would miss this
            "intent_category": "dose_change_request",
        },
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


def test_chat_diagnosis_intent_is_blocked(client, db_session, monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    response = client.post(
        "/ai/chat",
        json={
            "case_id": case.id,
            "message": "¡Creo que tengo una infección?",   # Spanish
            "intent_category": "diagnosis_request",
        },
        headers=_auth_headers(patient),
    )

    body = response.json()
    assert body["in_scope"] is False
    assert body["escalate"] is True


def test_chat_default_intent_is_general_question(client, db_session, monkeypatch):
    """Omitting intent_category defaults to general_question (in_scope=True)."""
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    response = client.post(
        "/ai/chat",
        json={"case_id": case.id, "message": "What are my medications?"},
        headers=_auth_headers(patient),
    )

    assert response.status_code == 200
    assert response.json()["in_scope"] is True


def test_chat_persists_both_turns(client, db_session, monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    client.post(
        "/ai/chat",
        json={"case_id": case.id, "message": "How should I take my ibuprofen?"},
        headers=_auth_headers(patient),
    )

    messages = db_session.query(models.ChatMessage).filter_by(case_id=case.id).all()
    assert len(messages) == 2
    assert messages[0].role == models.ChatRole.user
    assert messages[1].role == models.ChatRole.assistant


def test_chat_streaming(client, db_session, monkeypatch):
    monkeypatch.setattr('app.routers.ai.generate_recommendation_stream', lambda *args, **kwargs: (c for c in ["Test", " Chunk"]))
    patient, case = _make_case_with_meds(db_session)
    response = client.post(
        "/ai/chat/stream",
        json={"case_id": case.id, "message": "Test"},
        headers=_auth_headers(patient)
    )
    assert response.status_code == 200
    assert response.text == "Test Chunk"
