import functools
import inspect
import json
import logging
import os
import time
from typing import Any, Callable

logger = logging.getLogger(__name__)

# Token pricing per 1,000,000 tokens (USD)
MODEL_PRICING: dict[str, dict[str, float]] = {
    "meta-llama/llama-3-8b-instruct": {"prompt": 0.055, "completion": 0.055},
    "meta-llama/llama-3.1-8b-instruct": {"prompt": 0.055, "completion": 0.055},
    "meta-llama/llama-3-70b-instruct": {"prompt": 0.59, "completion": 0.79},
    "openai/gpt-4o-mini": {"prompt": 0.15, "completion": 0.60},
    "openai/gpt-4o": {"prompt": 2.50, "completion": 10.00},
    "anthropic/claude-3-5-sonnet": {"prompt": 3.00, "completion": 15.00},
    "openai/text-embedding-ada-002": {"prompt": 0.10, "completion": 0.00},
    "default": {"prompt": 0.20, "completion": 0.80},
}


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
    pricing = MODEL_PRICING.get(model, MODEL_PRICING.get("default", {"prompt": 0.20, "completion": 0.80}))
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


def track_llm_ops(
    name: str = "llm_operation",
    model: str | None = None,
) -> Callable:
    """Decorator to measure and log LLM Ops token counts and estimated costs.

    Runs before (estimating input tokens & prompt cost) and after (measuring
    generated output tokens, latency, and full cost) execution. Also records
    telemetry on active OpenTelemetry / Phoenix spans if present.
    """
    def decorator(func: Callable) -> Callable:
        target_model = model or os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3-8b-instruct")

        if inspect.isasyncgenfunction(func):
            @functools.wraps(func)
            async def async_gen_wrapper(*args: Any, **kwargs: Any):
                prompt_text = _extract_prompt_text(*args, **kwargs)
                prompt_tokens = count_tokens(prompt_text, model=target_model)
                initial_cost = calculate_cost(prompt_tokens, 0, model=target_model)

                # BEFORE execution
                logger.info(
                    "[LLMOps BEFORE] %s starting | model=%s | prompt_tokens_est=%d | prompt_cost_est=$%.6f",
                    name, target_model, prompt_tokens, initial_cost["prompt_cost_usd"]
                )

                try:
                    from opentelemetry import trace
                    span = trace.get_current_span()
                    if span.is_recording():
                        span.set_attribute("llm.operation", name)
                        span.set_attribute("llm.model_name", target_model)
                        span.set_attribute("llm.token_count.prompt_estimated", prompt_tokens)
                        span.set_attribute("llm.cost.prompt_estimated_usd", initial_cost["prompt_cost_usd"])
                except Exception:
                    pass

                start_time = time.perf_counter()
                accumulated_chunks: list[str] = []

                try:
                    async for chunk in func(*args, **kwargs):
                        if isinstance(chunk, str):
                            accumulated_chunks.append(chunk)
                        yield chunk
                finally:
                    # AFTER execution
                    duration_ms = (time.perf_counter() - start_time) * 1000.0
                    output_text = "".join(accumulated_chunks)
                    completion_tokens = count_tokens(output_text, model=target_model)
                    final_cost = calculate_cost(prompt_tokens, completion_tokens, model=target_model)

                    logger.info(
                        "[LLMOps AFTER] %s finished in %.2fms | model=%s | prompt_tokens=%d | completion_tokens=%d | total_tokens=%d | total_cost=$%.6f",
                        name, duration_ms, target_model,
                        final_cost["prompt_tokens"], final_cost["completion_tokens"],
                        final_cost["total_tokens"], final_cost["total_cost_usd"]
                    )

                    try:
                        from opentelemetry import trace
                        span = trace.get_current_span()
                        if span.is_recording():
                            span.set_attribute("llm.token_count.prompt", final_cost["prompt_tokens"])
                            span.set_attribute("llm.token_count.completion", final_cost["completion_tokens"])
                            span.set_attribute("llm.token_count.total", final_cost["total_tokens"])
                            span.set_attribute("llm.cost.prompt_usd", final_cost["prompt_cost_usd"])
                            span.set_attribute("llm.cost.completion_usd", final_cost["completion_cost_usd"])
                            span.set_attribute("llm.cost.total_cost_usd", final_cost["total_cost_usd"])
                            span.set_attribute("llm.duration_ms", round(duration_ms, 2))
                    except Exception:
                        pass

            return async_gen_wrapper

        elif inspect.iscoroutinefunction(func):
            @functools.wraps(func)
            async def async_wrapper(*args: Any, **kwargs: Any):
                prompt_text = _extract_prompt_text(*args, **kwargs)
                prompt_tokens = count_tokens(prompt_text, model=target_model)
                initial_cost = calculate_cost(prompt_tokens, 0, model=target_model)

                # BEFORE execution
                logger.info(
                    "[LLMOps BEFORE] %s starting | model=%s | prompt_tokens_est=%d | prompt_cost_est=$%.6f",
                    name, target_model, prompt_tokens, initial_cost["prompt_cost_usd"]
                )

                try:
                    from opentelemetry import trace
                    span = trace.get_current_span()
                    if span.is_recording():
                        span.set_attribute("llm.operation", name)
                        span.set_attribute("llm.model_name", target_model)
                        span.set_attribute("llm.token_count.prompt_estimated", prompt_tokens)
                        span.set_attribute("llm.cost.prompt_estimated_usd", initial_cost["prompt_cost_usd"])
                except Exception:
                    pass

                start_time = time.perf_counter()
                result = await func(*args, **kwargs)
                duration_ms = (time.perf_counter() - start_time) * 1000.0

                # AFTER execution
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
                    "[LLMOps AFTER] %s finished in %.2fms | model=%s | prompt_tokens=%d | completion_tokens=%d | total_tokens=%d | total_cost=$%.6f",
                    name, duration_ms, target_model,
                    final_cost["prompt_tokens"], final_cost["completion_tokens"],
                    final_cost["total_tokens"], final_cost["total_cost_usd"]
                )

                try:
                    from opentelemetry import trace
                    span = trace.get_current_span()
                    if span.is_recording():
                        span.set_attribute("llm.token_count.prompt", final_cost["prompt_tokens"])
                        span.set_attribute("llm.token_count.completion", final_cost["completion_tokens"])
                        span.set_attribute("llm.token_count.total", final_cost["total_tokens"])
                        span.set_attribute("llm.cost.prompt_usd", final_cost["prompt_cost_usd"])
                        span.set_attribute("llm.cost.completion_usd", final_cost["completion_cost_usd"])
                        span.set_attribute("llm.cost.total_cost_usd", final_cost["total_cost_usd"])
                        span.set_attribute("llm.duration_ms", round(duration_ms, 2))
                except Exception:
                    pass

                return result

            return async_wrapper

        else:
            @functools.wraps(func)
            def sync_wrapper(*args: Any, **kwargs: Any):
                prompt_text = _extract_prompt_text(*args, **kwargs)
                prompt_tokens = count_tokens(prompt_text, model=target_model)
                initial_cost = calculate_cost(prompt_tokens, 0, model=target_model)

                # BEFORE execution
                logger.info(
                    "[LLMOps BEFORE] %s starting | model=%s | prompt_tokens_est=%d | prompt_cost_est=$%.6f",
                    name, target_model, prompt_tokens, initial_cost["prompt_cost_usd"]
                )

                start_time = time.perf_counter()
                result = func(*args, **kwargs)
                duration_ms = (time.perf_counter() - start_time) * 1000.0

                # AFTER execution
                completion_tokens = 0
                if hasattr(result, "usage") and result.usage:
                    prompt_tokens = getattr(result.usage, "prompt_tokens", prompt_tokens)
                    completion_tokens = getattr(result.usage, "completion_tokens", 0)
                elif isinstance(result, str):
                    completion_tokens = count_tokens(result, model=target_model)

                final_cost = calculate_cost(prompt_tokens, completion_tokens, model=target_model)

                logger.info(
                    "[LLMOps AFTER] %s finished in %.2fms | model=%s | prompt_tokens=%d | completion_tokens=%d | total_tokens=%d | total_cost=$%.6f",
                    name, duration_ms, target_model,
                    final_cost["prompt_tokens"], final_cost["completion_tokens"],
                    final_cost["total_tokens"], final_cost["total_cost_usd"]
                )

                return result

            return sync_wrapper

    return decorator


def setup_tracing() -> None:
    endpoint = os.getenv("PHOENIX_COLLECTOR_ENDPOINT")
    if not endpoint:
        return

    from openinference.instrumentation.openai import OpenAIInstrumentor
    from phoenix.otel import register

    tracer_provider = register(project_name=os.getenv("PHOENIX_PROJECT_NAME", "remote-carepro"))
    OpenAIInstrumentor().instrument(tracer_provider=tracer_provider)
