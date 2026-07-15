from app import models
from app.providers.auth import CognitoAuthProvider, LocalAuthProvider, get_auth_provider
from app.providers.fda import FixtureFDAProvider, LiveFDAProvider, get_fda_provider
from app.providers.llm import MockLLMProvider, OpenRouterProvider, get_llm_provider
from app.security import create_access_token, hash_password


def test_get_auth_provider_defaults_to_local(monkeypatch):
    monkeypatch.delenv("AUTH_PROVIDER", raising=False)
    assert isinstance(get_auth_provider(), LocalAuthProvider)


def test_get_auth_provider_cognito(monkeypatch):
    monkeypatch.setenv("AUTH_PROVIDER", "cognito")
    assert isinstance(get_auth_provider(), CognitoAuthProvider)


def test_get_fda_provider_defaults_to_live(monkeypatch):
    monkeypatch.delenv("FDA_PROVIDER", raising=False)
    assert isinstance(get_fda_provider(), LiveFDAProvider)


def test_get_fda_provider_fixture(monkeypatch):
    monkeypatch.setenv("FDA_PROVIDER", "fixture")
    assert isinstance(get_fda_provider(), FixtureFDAProvider)


def test_get_llm_provider_defaults_to_mock(monkeypatch):
    monkeypatch.delenv("LLM_PROVIDER", raising=False)
    assert isinstance(get_llm_provider(), MockLLMProvider)


def test_get_llm_provider_openrouter(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openrouter")
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-key")
    assert isinstance(get_llm_provider(), OpenRouterProvider)


def test_get_current_user_via_local_provider(client, db_session, monkeypatch):
    monkeypatch.delenv("AUTH_PROVIDER", raising=False)

    user = models.User(
        email="factory-test@example.com",
        full_name="Factory Test",
        role=models.UserRole.clinician,
        password_hash=hash_password("pw"),
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    token = create_access_token({"sub": user.id, "role": "clinician", "email": user.email})
    response = client.get("/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert response.json()["email"] == "factory-test@example.com"
