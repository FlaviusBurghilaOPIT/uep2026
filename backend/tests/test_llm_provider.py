import asyncio
from types import SimpleNamespace
from unittest.mock import AsyncMock

from app.providers.llm import OpenRouterProvider


def _fake_completion(content: str):
    return SimpleNamespace(choices=[SimpleNamespace(message=SimpleNamespace(content=content))])


def test_client_points_at_openrouter_with_env_config(monkeypatch):
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-key")
    monkeypatch.delenv("OPENROUTER_MODEL", raising=False)

    provider = OpenRouterProvider()

    # AsyncOpenAI normalizes base_url with a trailing slash
    assert str(provider._client.base_url) == "https://openrouter.ai/api/v1/"
    assert provider._model == "openai/gpt-4o-mini"


def test_chat_sends_system_first_and_returns_content(monkeypatch):
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-key")
    monkeypatch.setenv("OPENROUTER_MODEL", "test/model")

    provider = OpenRouterProvider()
    create_mock = AsyncMock(return_value=_fake_completion("hello from llm"))
    monkeypatch.setattr(provider._client.chat.completions, "create", create_mock)

    reply = asyncio.run(
        provider.chat(
            messages=[{"role": "user", "content": "hi"}],
            system="system prompt",
        )
    )

    assert reply == "hello from llm"
    create_mock.assert_awaited_once_with(
        model="test/model",
        messages=[
            {"role": "system", "content": "system prompt"},
            {"role": "user", "content": "hi"},
        ],
    )


def test_chat_returns_empty_string_when_content_is_none(monkeypatch):
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-key")
    monkeypatch.setenv("OPENROUTER_MODEL", "test/model")

    provider = OpenRouterProvider()
    create_mock = AsyncMock(return_value=_fake_completion(None))
    monkeypatch.setattr(provider._client.chat.completions, "create", create_mock)

    reply = asyncio.run(
        provider.chat(
            messages=[{"role": "user", "content": "hi"}],
            system="system prompt",
        )
    )

    assert reply == ""
