import functools
import inspect
import json
import logging
import os
import time
from typing import Any, Callable

from dotenv import load_dotenv

logger = logging.getLogger(__name__)

load_dotenv()

# Single source of truth for "which model answers chat" — every LLM call site
# (recommendation stream, patient summary, FDA triage) must import CHAT_MODEL
# instead of reading OPENROUTER_MODEL itself, otherwise a missing env var used
# to make different code paths silently fall back to different models, which
# breaks response consistency and prompt caching. No default: unset must fail
# startup loudly instead of guessing.
CHAT_MODEL = os.getenv("OPENROUTER_MODEL")
if not CHAT_MODEL:
    raise RuntimeError(
        "CRITICAL: OPENROUTER_MODEL must be set in .env — there is no default. "
        "Every LLM call in the app must share this one model."
    )

EMBEDDING_MODEL = os.getenv("OPENROUTER_EMBEDDING_MODEL", "openai/text-embedding-ada-002")

# Token pricing per 1,000,000 tokens (USD)
MODEL_PRICING: dict[str, dict[str, float]] = {
    "deepseek/deepseek-v4-flash-0731": {"prompt": 0.065, "completion": 0.18},
    "meta-llama/llama-3-8b-instruct": {"prompt": 0.055, "completion": 0.055},
    "meta-llama/llama-3.1-8b-instruct": {"prompt": 0.055, "completion": 0.055},
    "meta-llama/llama-3-70b-instruct": {"prompt": 0.59, "completion": 0.79},
    "openai/gpt-4o-mini": {"prompt": 0.15, "completion": 0.60},
    "openai/gpt-4o": {"prompt": 2.50, "completion": 10.00},
    "anthropic/claude-3-5-sonnet": {"prompt": 3.00, "completion": 15.00},
    "openai/text-embedding-ada-002": {"prompt": 0.10, "completion": 0.00},
    "default": {"prompt": 0.20, "completion": 0.80},
}

_LAST_PRICING_SYNC_TIME: float = 0.0
_SYNC_INTERVAL_SECONDS: float = 3600.0


def fetch_openrouter_pricing(target_model: str | None = None) -> dict[str, float] | None:
    """Fetch real-time model pricing from OpenRouter public API and cache locally."""
    global _LAST_PRICING_SYNC_TIME
    now = time.time()
    if target_model and target_model in MODEL_PRICING and (now - _LAST_PRICING_SYNC_TIME < _SYNC_INTERVAL_SECONDS):
        return MODEL_PRICING[target_model]

    try:
        import httpx
        url = "https://openrouter.ai/api/v1/models"
        headers = {"User-Agent": "RemoteCarePro/1.0"}
        api_key = os.getenv("OPENROUTER_API_KEY")
        if api_key and not api_key.startswith("sk-or-your"):
            headers["Authorization"] = f"Bearer {api_key}"

        with httpx.Client(timeout=3.0) as client:
            resp = client.get(url, headers=headers)
            if resp.status_code == 200:
                data = resp.json().get("data", [])
                for item in data:
                    mid = item.get("id")
                    pricing = item.get("pricing", {})
                    if mid and pricing:
                        prompt_p = float(pricing.get("prompt", 0) or 0) * 1_000_000.0
                        comp_p = float(pricing.get("completion", 0) or 0) * 1_000_000.0
                        MODEL_PRICING[mid] = {"prompt": prompt_p, "completion": comp_p}
                _LAST_PRICING_SYNC_TIME = now
                if target_model and target_model in MODEL_PRICING:
                    return MODEL_PRICING[target_model]
    except Exception as e:
        logger.debug("Failed to fetch dynamic OpenRouter model pricing: %s", e)

    return MODEL_PRICING.get(target_model) if target_model else None


def get_model_pricing(model: str) -> dict[str, float]:
    """Retrieve USD pricing per million tokens, querying OpenRouter dynamically with static fallback."""
    if model in MODEL_PRICING:
        return MODEL_PRICING[model]

    fetched = fetch_openrouter_pricing(target_model=model)
    if fetched:
        return fetched

    return MODEL_PRICING.get("default", {"prompt": 0.20, "completion": 0.80})


def count_tokens(text: str, model: str = "gpt-4o-mini") -> int:
    """Estimate token count using tiktoken (with character heuristic fallback)."""
    if not text:
        return 0
    try:
        import tiktoken
        try:
            encoding = tiktoken.encoding_for_model(model)
        except Exception:
            encoding = tiktoken.get_encoding("cl100k_base")
        return len(encoding.encode(text))
    except Exception:
        # ~4 chars per token fallback
        return max(1, len(text) // 4)


def calculate_cost(
    prompt_tokens: int,
    completion_tokens: int,
    model: str = "meta-llama/llama-3-8b-instruct",
) -> dict[str, Any]:
    """Calculate USD costs for prompt, completion, and total token usage."""
    pricing = get_model_pricing(model)
    prompt_cost = (prompt_tokens / 1_000_000.0) * pricing["prompt"]
    completion_cost = (completion_tokens / 1_000_000.0) * pricing["completion"]
    total_cost = prompt_cost + completion_cost
    return {
        "model": model,
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "total_tokens": prompt_tokens + completion_tokens,
        "prompt_cost_usd": round(prompt_cost, 8),
        "completion_cost_usd": round(completion_cost, 8),
        "total_cost_usd": round(total_cost, 8),
    }


def _extract_prompt_text(*args: Any, **kwargs: Any) -> str:
    """Extract readable text representations from function arguments for token estimation."""
    parts: list[str] = []
    for arg in args:
        if isinstance(arg, str):
            parts.append(arg)
        elif isinstance(arg, dict):
            parts.append(json.dumps(arg))
        elif isinstance(arg, list):
            for item in arg:
                if isinstance(item, dict) and "content" in item:
                    parts.append(str(item["content"]))
                elif isinstance(item, str):
                    parts.append(item)
    for k, v in kwargs.items():
        if isinstance(v, str):
            parts.append(v)
        elif isinstance(v, dict):
            parts.append(json.dumps(v))
        elif isinstance(v, list):
            for item in v:
                if isinstance(item, dict) and "content" in item:
                    parts.append(str(item["content"]))
                elif isinstance(item, str):
                    parts.append(item)
    return " ".join(parts)


LLM_PROVIDER_NAME = "openrouter"


def _get_tracer():
    """Module tracer. Safe to call even when Phoenix was never configured —
    returns a no-op tracer whose spans don't record, so set_attribute() is a
    harmless no-op instead of raising."""
    from opentelemetry import trace
    return trace.get_tracer(__name__)


def _audit_attributes(kwargs: dict[str, Any]) -> dict[str, Any]:
    """Ties a span back to the case/patient/clinician that triggered it.

    `session.id` and `user.id` are OpenInference's own conventions — Phoenix
    uses `session.id` to group every span from the same case's back-and-forth
    conversation into one thread in its Sessions view, so setting it to
    `case_id` is what makes turns of the same conversation link together.
    """
    case_id = kwargs.get("case_id") or kwargs.get("session_id")
    patient_id = kwargs.get("patient_id") or kwargs.get("user_id")
    clinician_id = kwargs.get("clinician_id")
    requester_role = kwargs.get("requester_role")

    attrs: dict[str, Any] = {}
    if case_id:
        attrs["session.id"] = str(case_id)
    if patient_id:
        attrs["user.id"] = str(patient_id)

    audit_meta = {
        k: v
        for k, v in {
            "case_id": case_id,
            "patient_id": patient_id,
            "clinician_id": clinician_id,
            "requester_role": requester_role,
        }.items()
        if v
    }
    if audit_meta:
        attrs["metadata"] = json.dumps(audit_meta)
    return attrs


def _set_span_attributes(span: Any, attrs: dict[str, Any]) -> None:
    for key, value in attrs.items():
        span.set_attribute(key, value)


def track_llm_ops(
    name: str = "llm_operation",
    model: str | None = None,
) -> Callable:
    """Decorator to measure and log LLM Ops token counts and estimated costs.

    Runs before (estimating input tokens & prompt cost) and after (measuring
    generated output tokens, latency, and full cost) execution, and always
    opens its own OpenTelemetry span for that window — a decorated call used
    to only *look for* an already-current span and silently do nothing if
    none was active (which was always true in production, since nothing else
    in the request path opens one), so no cost/token attribute was ever
    actually attached to a span and Phoenix showed $0. Recognizes optional
    `case_id`/`patient_id`/`clinician_id`/`requester_role` kwargs (any of
    them) on the decorated call and stamps them onto the span for
    session grouping and per-case/per-patient audit lookups.
    """
    def decorator(func: Callable) -> Callable:
        target_model = model or CHAT_MODEL

        if inspect.isasyncgenfunction(func):
            @functools.wraps(func)
            async def async_gen_wrapper(*args: Any, **kwargs: Any):
                prompt_text = _extract_prompt_text(*args, **kwargs)
                prompt_tokens = count_tokens(prompt_text, model=target_model)
                initial_cost = calculate_cost(prompt_tokens, 0, model=target_model)

                logger.info(
                    "[LLMOps BEFORE] %s starting | model=%s | prompt_tokens_est=%d | prompt_cost_est=$%.8f",
                    name, target_model, prompt_tokens, initial_cost["prompt_cost_usd"]
                )

                tracer = _get_tracer()
                with tracer.start_as_current_span(name) as span:
                    span.set_attribute("llm.operation", name)
                    span.set_attribute("llm.model_name", target_model)
                    span.set_attribute("llm.provider", LLM_PROVIDER_NAME)
                    span.set_attribute("llm.token_count.prompt_estimated", prompt_tokens)
                    span.set_attribute("llm.cost.prompt_estimated_usd", initial_cost["prompt_cost_usd"])
                    _set_span_attributes(span, _audit_attributes(kwargs))

                    start_time = time.perf_counter()
                    accumulated_chunks: list[str] = []

                    try:
                        async for chunk in func(*args, **kwargs):
                            if isinstance(chunk, str):
                                accumulated_chunks.append(chunk)
                            yield chunk
                    finally:
                        duration_ms = (time.perf_counter() - start_time) * 1000.0
                        output_text = "".join(accumulated_chunks)
                        completion_tokens = count_tokens(output_text, model=target_model)
                        final_cost = calculate_cost(prompt_tokens, completion_tokens, model=target_model)

                        logger.info(
                            "[LLMOps AFTER] %s finished in %.2fms | model=%s | prompt_tokens=%d | completion_tokens=%d | total_tokens=%d | total_cost=$%.8f",
                            name, duration_ms, target_model,
                            final_cost["prompt_tokens"], final_cost["completion_tokens"],
                            final_cost["total_tokens"], final_cost["total_cost_usd"]
                        )

                        span.set_attribute("llm.token_count.prompt", final_cost["prompt_tokens"])
                        span.set_attribute("llm.token_count.completion", final_cost["completion_tokens"])
                        span.set_attribute("llm.token_count.total", final_cost["total_tokens"])
                        span.set_attribute("llm.cost.prompt", final_cost["prompt_cost_usd"])
                        span.set_attribute("llm.cost.completion", final_cost["completion_cost_usd"])
                        span.set_attribute("llm.cost.total", final_cost["total_cost_usd"])
                        span.set_attribute("llm.duration_ms", round(duration_ms, 2))

            return async_gen_wrapper

        elif inspect.iscoroutinefunction(func):
            @functools.wraps(func)
            async def async_wrapper(*args: Any, **kwargs: Any):
                prompt_text = _extract_prompt_text(*args, **kwargs)
                prompt_tokens = count_tokens(prompt_text, model=target_model)
                initial_cost = calculate_cost(prompt_tokens, 0, model=target_model)

                logger.info(
                    "[LLMOps BEFORE] %s starting | model=%s | prompt_tokens_est=%d | prompt_cost_est=$%.8f",
                    name, target_model, prompt_tokens, initial_cost["prompt_cost_usd"]
                )

                tracer = _get_tracer()
                with tracer.start_as_current_span(name) as span:
                    span.set_attribute("llm.operation", name)
                    span.set_attribute("llm.model_name", target_model)
                    span.set_attribute("llm.provider", LLM_PROVIDER_NAME)
                    span.set_attribute("llm.token_count.prompt_estimated", prompt_tokens)
                    span.set_attribute("llm.cost.prompt_estimated_usd", initial_cost["prompt_cost_usd"])
                    _set_span_attributes(span, _audit_attributes(kwargs))

                    start_time = time.perf_counter()
                    result = await func(*args, **kwargs)
                    duration_ms = (time.perf_counter() - start_time) * 1000.0

                    completion_tokens = 0
                    if hasattr(result, "usage") and result.usage:
                        prompt_tokens = getattr(result.usage, "prompt_tokens", prompt_tokens)
                        completion_tokens = getattr(result.usage, "completion_tokens", 0)
                    elif isinstance(result, str):
                        completion_tokens = count_tokens(result, model=target_model)
                    elif isinstance(result, dict) and "reply" in result:
                        completion_tokens = count_tokens(str(result["reply"]), model=target_model)

                    final_cost = calculate_cost(prompt_tokens, completion_tokens, model=target_model)

                    logger.info(
                        "[LLMOps AFTER] %s finished in %.2fms | model=%s | prompt_tokens=%d | completion_tokens=%d | total_tokens=%d | total_cost=$%.8f",
                        name, duration_ms, target_model,
                        final_cost["prompt_tokens"], final_cost["completion_tokens"],
                        final_cost["total_tokens"], final_cost["total_cost_usd"]
                    )

                    span.set_attribute("llm.token_count.prompt", final_cost["prompt_tokens"])
                    span.set_attribute("llm.token_count.completion", final_cost["completion_tokens"])
                    span.set_attribute("llm.token_count.total", final_cost["total_tokens"])
                    span.set_attribute("llm.cost.prompt", final_cost["prompt_cost_usd"])
                    span.set_attribute("llm.cost.completion", final_cost["completion_cost_usd"])
                    span.set_attribute("llm.cost.total", final_cost["total_cost_usd"])
                    span.set_attribute("llm.duration_ms", round(duration_ms, 2))

                return result

            return async_wrapper

        else:
            @functools.wraps(func)
            def sync_wrapper(*args: Any, **kwargs: Any):
                prompt_text = _extract_prompt_text(*args, **kwargs)
                prompt_tokens = count_tokens(prompt_text, model=target_model)
                initial_cost = calculate_cost(prompt_tokens, 0, model=target_model)

                logger.info(
                    "[LLMOps BEFORE] %s starting | model=%s | prompt_tokens_est=%d | prompt_cost_est=$%.8f",
                    name, target_model, prompt_tokens, initial_cost["prompt_cost_usd"]
                )

                tracer = _get_tracer()
                with tracer.start_as_current_span(name) as span:
                    span.set_attribute("llm.operation", name)
                    span.set_attribute("llm.model_name", target_model)
                    span.set_attribute("llm.provider", LLM_PROVIDER_NAME)
                    span.set_attribute("llm.token_count.prompt_estimated", prompt_tokens)
                    span.set_attribute("llm.cost.prompt_estimated_usd", initial_cost["prompt_cost_usd"])
                    _set_span_attributes(span, _audit_attributes(kwargs))

                    start_time = time.perf_counter()
                    result = func(*args, **kwargs)
                    duration_ms = (time.perf_counter() - start_time) * 1000.0

                    completion_tokens = 0
                    if hasattr(result, "usage") and result.usage:
                        prompt_tokens = getattr(result.usage, "prompt_tokens", prompt_tokens)
                        completion_tokens = getattr(result.usage, "completion_tokens", 0)
                    elif isinstance(result, str):
                        completion_tokens = count_tokens(result, model=target_model)

                    final_cost = calculate_cost(prompt_tokens, completion_tokens, model=target_model)

                    logger.info(
                        "[LLMOps AFTER] %s finished in %.2fms | model=%s | prompt_tokens=%d | completion_tokens=%d | total_tokens=%d | total_cost=$%.8f",
                        name, duration_ms, target_model,
                        final_cost["prompt_tokens"], final_cost["completion_tokens"],
                        final_cost["total_tokens"], final_cost["total_cost_usd"]
                    )

                    span.set_attribute("llm.token_count.prompt", final_cost["prompt_tokens"])
                    span.set_attribute("llm.token_count.completion", final_cost["completion_tokens"])
                    span.set_attribute("llm.token_count.total", final_cost["total_tokens"])
                    span.set_attribute("llm.cost.prompt", final_cost["prompt_cost_usd"])
                    span.set_attribute("llm.cost.completion", final_cost["completion_cost_usd"])
                    span.set_attribute("llm.cost.total", final_cost["total_cost_usd"])

                return result

            return sync_wrapper

    return decorator


def setup_tracing() -> None:
    endpoint = os.getenv("PHOENIX_COLLECTOR_ENDPOINT")
    if not endpoint:
        return

    from openinference.instrumentation.openai import OpenAIInstrumentor
    from phoenix.otel import register

    # Passing endpoint/protocol explicitly avoids register()'s auto-detect
    # path, which (as of arize-phoenix-otel in requirements.txt) derives the
    # gRPC port (4317) for the netloc while still reporting "HTTP + protobuf"
    # transport and keeping the /v1/traces path — spans silently fail to
    # export to that dead combination and Phoenix shows zero traces.
    tracer_provider = register(
        project_name=os.getenv("PHOENIX_PROJECT_NAME", "remote-carepro"),
        endpoint=endpoint,
        protocol="http/protobuf",
    )
    OpenAIInstrumentor().instrument(tracer_provider=tracer_provider)
