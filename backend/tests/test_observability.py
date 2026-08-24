import pytest
from unittest.mock import MagicMock

pytest.importorskip("openinference.instrumentation.openai")
pytest.importorskip("phoenix.otel")

import openinference.instrumentation.openai
import phoenix.otel

from app.observability import (
    setup_tracing,
    count_tokens,
    calculate_cost,
    track_llm_ops,
    MODEL_PRICING,
)


@pytest.fixture
def anyio_backend():
    return "asyncio"


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


def test_count_tokens():
    assert count_tokens("") == 0
    tokens = count_tokens("Patient asks for postoperative instructions.", model="openai/gpt-4o-mini")
    assert tokens > 0
    assert isinstance(tokens, int)


def test_calculate_cost():
    model = "meta-llama/llama-3-8b-instruct"
    pricing = MODEL_PRICING[model]
    prompt_tokens = 1_000
    completion_tokens = 500

    cost_info = calculate_cost(prompt_tokens, completion_tokens, model=model)
    expected_prompt_cost = (1_000 / 1_000_000) * pricing["prompt"]
    expected_completion_cost = (500 / 1_000_000) * pricing["completion"]

    assert cost_info["model"] == model
    assert cost_info["prompt_tokens"] == 1_000
    assert cost_info["completion_tokens"] == 500
    assert cost_info["total_tokens"] == 1_500
    assert cost_info["prompt_cost_usd"] == round(expected_prompt_cost, 8)
    assert cost_info["completion_cost_usd"] == round(expected_completion_cost, 8)
    assert cost_info["total_cost_usd"] == round(expected_prompt_cost + expected_completion_cost, 8)


@pytest.mark.anyio
async def test_track_llm_ops_async_function(caplog):
    @track_llm_ops(name="test_async_op", model="openai/gpt-4o-mini")
    async def sample_llm_call(prompt: str) -> str:
        return "Take medication with water."

    with caplog.at_level("INFO"):
        result = await sample_llm_call("How do I take this medicine?")

    assert result == "Take medication with water."
    assert any("[LLMOps BEFORE] test_async_op starting" in record.message for record in caplog.records)
    assert any("[LLMOps AFTER] test_async_op finished" in record.message for record in caplog.records)


@pytest.mark.anyio
async def test_track_llm_ops_async_generator(caplog):
    @track_llm_ops(name="test_stream_op", model="meta-llama/llama-3-8b-instruct")
    async def sample_stream(prompt: str):
        yield "Hello "
        yield "Patient!"

    with caplog.at_level("INFO"):
        chunks = [chunk async for chunk in sample_stream("Hello doctor")]

    assert "".join(chunks) == "Hello Patient!"
    assert any("[LLMOps BEFORE] test_stream_op starting" in record.message for record in caplog.records)
    assert any("[LLMOps AFTER] test_stream_op finished" in record.message for record in caplog.records)


def test_track_llm_ops_sync_function(caplog):
    @track_llm_ops(name="test_sync_op", model="openai/gpt-4o-mini")
    def sample_sync(prompt: str) -> str:
        return "Sync answer"

    with caplog.at_level("INFO"):
        res = sample_sync("Hello")

    assert res == "Sync answer"
    assert any("[LLMOps BEFORE] test_sync_op starting" in record.message for record in caplog.records)
    assert any("[LLMOps AFTER] test_sync_op finished" in record.message for record in caplog.records)


@pytest.mark.anyio
async def test_track_llm_ops_populates_span_attributes():
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export.in_memory_span_exporter import InMemorySpanExporter
    from opentelemetry.sdk.trace.export import SimpleSpanProcessor

    exporter = InMemorySpanExporter()
    provider = TracerProvider()
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    tracer = provider.get_tracer("test-tracer")

    @track_llm_ops(name="span_tracked_op", model="openai/gpt-4o-mini")
    async def sample_llm_call(prompt: str) -> str:
        return "You should rest for 2 days."

    with tracer.start_as_current_span("parent_span"):
        result = await sample_llm_call("How much should I rest?")

    assert result == "You should rest for 2 days."
    spans = exporter.get_finished_spans()
    assert len(spans) == 1
    span = spans[0]
    assert span.attributes["llm.operation"] == "span_tracked_op"
    assert span.attributes["llm.model_name"] == "openai/gpt-4o-mini"
    assert span.attributes["llm.token_count.prompt"] > 0
    assert span.attributes["llm.token_count.completion"] > 0
    assert (
        span.attributes["llm.token_count.total"]
        == span.attributes["llm.token_count.prompt"] + span.attributes["llm.token_count.completion"]
    )
    assert "llm.cost.total_cost_usd" in span.attributes
    assert span.attributes["llm.cost.total_cost_usd"] > 0
