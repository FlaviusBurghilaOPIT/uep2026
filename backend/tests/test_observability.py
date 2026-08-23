from unittest.mock import MagicMock
import pytest

pytest.importorskip("openinference.instrumentation.openai")
pytest.importorskip("phoenix.otel")

import openinference.instrumentation.openai
import phoenix.otel

from app.observability import setup_tracing


def test_setup_tracing_noops_without_endpoint(monkeypatch):
    monkeypatch.delenv("PHOENIX_COLLECTOR_ENDPOINT", raising=False)
    register_mock = MagicMock()
    monkeypatch.setattr(phoenix.otel, "register", register_mock)

    setup_tracing()

    register_mock.assert_not_called()


def test_setup_tracing_registers_and_instruments(monkeypatch):
    monkeypatch.setenv("PHOENIX_COLLECTOR_ENDPOINT", "http://localhost:6006")
    monkeypatch.setenv("PHOENIX_PROJECT_NAME", "test-project")
    register_mock = MagicMock()
    instrumentor_cls_mock = MagicMock()
    monkeypatch.setattr(phoenix.otel, "register", register_mock)
    monkeypatch.setattr(
        openinference.instrumentation.openai, "OpenAIInstrumentor", instrumentor_cls_mock
    )

    setup_tracing()

    register_mock.assert_called_once_with(project_name="test-project")
    instrumentor_cls_mock.return_value.instrument.assert_called_once_with(
        tracer_provider=register_mock.return_value
    )
