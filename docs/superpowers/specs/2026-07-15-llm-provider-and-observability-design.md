# Remote CarePro — LLM Provider Consolidation & Observability Design

Date: 2026-07-15
Branch target: `p5/backend`
Author context: Person 5 (FDA workflow, AI assistant, check-in, wiki, emergency contact)

## 1. Purpose

Three things, done together because they share the same seam (`app/providers/llm.py` and its two
call sites):

- **Consolidate the LLM provider**: remove the unimplemented `BedrockProvider` stub, implement
  `OpenRouterProvider` for real (it currently returns `None` — `LLMProvider.chat()`'s `pass` body
  was never filled in).
- **Add the FDA safety-panel LLM summarization** that the original `docs/PLAN.md` scoped
  ("call openFDA → summarize with the LLM → show plain-language safety info with a source label")
  but was never built — today `GET /fda/drug/{name}` returns raw openFDA/fixture JSON with no LLM
  involvement at all.
- **Add LLM observability via Arize Phoenix**, tracing both call sites (AI chat, FDA summary) for
  prompts, system prompts, input/output, and token consumption, wired into `docker-compose.yml`.

Alongside this: unit test coverage for all of the above, and a full-suite pass confirming nothing
existing regresses.

## 2. Current-state findings (baseline facts, not decisions)

- `backend/app/providers/llm.py`: `OpenRouterProvider.chat()` and `BedrockProvider.chat()` are both
  `pass` stubs — only `MockLLMProvider` actually returns anything. `LLM_PROVIDER=openrouter` in
  production silently returns `None` as the chat reply today.
- `backend/app/providers/fda.py`: `LiveFDAProvider`/`FixtureFDAProvider` have zero LLM involvement.
  `FixtureFDAProvider` returns `{"drug", "warnings", "source": "fixture"}`; `LiveFDAProvider`
  returns the raw openFDA response body. Bedrock was never wired into the FDA path in the first
  place — the "ai/fda" framing refers to the LLM provider being shared by two call sites, not to
  FDA ever having used Bedrock.
- `backend/app/routers/fda.py::get_drug_info` (`GET /fda/drug/{name}`) currently just returns
  `await provider.get_drug_info(name)` directly — no summarization step, no response schema
  (implicit `dict`).
- The FDA warnings queue (`GET /fda/warnings`, `/approve`, `/dismiss`, `POST /fda/warnings/refresh`)
  is a separate, already-implemented feature from a prior hardening pass. It does not call the LLM
  and is out of scope for this change — `POST /fda/warnings/refresh` keeps its existing raw-text
  truncation behavior.
- No LLM observability/tracing exists anywhere in the codebase.
- `docker-compose.yml` has no Phoenix (or any observability) service.
- `backend/requirements.txt` has no `openai`, OpenTelemetry, or OpenInference packages, and no
  `boto3` (Bedrock removal touches no AWS SDK dependency — there wasn't one).
- `backend/tests/test_providers.py` currently asserts `get_llm_provider()` returns a
  `BedrockProvider` instance when `LLM_PROVIDER=bedrock` — this test is deleted as part of removing
  the class.
- The full backend suite is currently green: 32/32 passing (`cd backend && python -m pytest -v`,
  Postgres reachable on `localhost:5432` via the existing `docker compose up -d` stack).

## 3. LLM provider consolidation

Delete `BedrockProvider` entirely and its `"bedrock"` branch in `get_llm_provider()`. Implement
`OpenRouterProvider` for real using the `openai` Python SDK against OpenRouter's OpenAI-compatible
endpoint (chosen over raw `httpx` + hand-rolled parsing specifically because it makes the
observability step in §5 close to free — see decision log).

```python
import os
from abc import ABC, abstractmethod

from openai import AsyncOpenAI


class LLMProvider(ABC):
    @abstractmethod
    async def chat(self, messages: list[dict], system: str) -> str:
        pass


class MockLLMProvider(LLMProvider):
    async def chat(self, messages, system):
        return "This is a mock AI response. The real AI will answer here."


class OpenRouterProvider(LLMProvider):
    def __init__(self):
        self._client = AsyncOpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=os.getenv("OPENROUTER_API_KEY"),
        )
        self._model = os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini")

    async def chat(self, messages, system):
        response = await self._client.chat.completions.create(
            model=self._model,
            messages=[{"role": "system", "content": system}, *messages],
        )
        return response.choices[0].message.content


def get_llm_provider() -> LLMProvider:
    p = os.getenv("LLM_PROVIDER", "mock")
    if p == "openrouter":
        return OpenRouterProvider()
    return MockLLMProvider()
```

No error handling is added around the OpenRouter call — consistent with the rest of the codebase
(e.g. `LiveFDAProvider` doesn't catch `httpx` errors either); failures propagate as FastAPI 500s.

## 4. FDA safety-panel summarization

`FDAProvider` subclasses gain a `source: str` class attribute so the router doesn't need
`isinstance` checks:

```python
class FDAProvider(ABC):
    source: str

    @abstractmethod
    async def get_drug_info(self, drug_name: str) -> dict:
        pass


class LiveFDAProvider(FDAProvider):
    source = "live"
    ...


class FixtureFDAProvider(FDAProvider):
    source = "fixture"
    ...
```

New response schema in `app/schemas.py`:

```python
class FDADrugInfoResponse(BaseModel):
    drug_name: str
    summary: str
    source: str
```

`GET /fda/drug/{name}` in `app/routers/fda.py` becomes:

```python
import json

FDA_SUMMARY_SYSTEM_PROMPT = (
    "You are a patient-facing drug safety summarizer. Given raw openFDA label data, "
    "produce a short, plain-language summary of key warnings and safety information. "
    "You are strictly informational: never advise changing a dose, never diagnose. "
    "If the data is sparse or missing, say so plainly rather than guessing."
)


@router.get("/drug/{name}", response_model=schemas.FDADrugInfoResponse)
async def get_drug_info(name: str, current_user: models.User = Depends(get_current_user)):
    provider = get_fda_provider()
    raw = await provider.get_drug_info(name)

    llm = get_llm_provider()
    summary = await llm.chat(
        messages=[{"role": "user", "content": json.dumps(raw)[:4000]}],
        system=FDA_SUMMARY_SYSTEM_PROMPT,
    )

    return schemas.FDADrugInfoResponse(drug_name=name, summary=summary, source=provider.source)
```

This only touches the on-demand `GET /fda/drug/{name}` endpoint. The warnings queue endpoints are
unchanged (see §2).

## 5. Observability (Arize Phoenix)

New module `backend/app/observability.py`:

```python
import os


def setup_tracing() -> None:
    endpoint = os.getenv("PHOENIX_COLLECTOR_ENDPOINT")
    if not endpoint:
        return

    from openinference.instrumentation.openai import OpenAIInstrumentor
    from phoenix.otel import register

    tracer_provider = register(project_name=os.getenv("PHOENIX_PROJECT_NAME", "remote-carepro"))
    OpenAIInstrumentor().instrument(tracer_provider=tracer_provider)
```

Called once near the top of `app/main.py`, immediately after `app = FastAPI(...)`. Gated entirely
on `PHOENIX_COLLECTOR_ENDPOINT` being set: absent in pytest (no-op, zero import cost, zero network
calls), present in `docker-compose.yml`.

Because `OpenRouterProvider` uses the real `openai` SDK, `OpenAIInstrumentor` auto-captures — with
no manual span code at either call site — for every OpenRouter call made through `/ai/chat` and the
new FDA summarization step:

- the system prompt and full input message list,
- the model output text,
- prompt / completion / total token counts,
- model name, latency, and errors.

Each call site additionally wraps its `llm.chat(...)` call in
`openinference.instrumentation.using_attributes(session_id=case_id, metadata={"endpoint": "..."})`
(`"ai.chat"` for the chat router, `"fda.summarize"` for the FDA router) so traces are filterable by
case and by call site in the Phoenix UI — a few extra lines given the library is already a
dependency.

Exact `register()` / `using_attributes()` keyword arguments will be verified against the installed
`arize-phoenix-otel` / `openinference-instrumentation-openai` package versions during
implementation rather than assumed from memory, since these are fast-moving libraries.

## 6. docker-compose

```yaml
  phoenix:
    image: arizephoenix/phoenix:latest
    ports:
      - "6006:6006"   # UI + OTLP http
      - "4317:4317"   # OTLP grpc
    volumes:
      - phoenix_data:/mnt/data

  backend:
    environment:
      PHOENIX_COLLECTOR_ENDPOINT: http://phoenix:4317
    depends_on:
      - phoenix
```

`phoenix_data` added to the top-level `volumes:` block alongside `pgdata`. No healthcheck /
`condition: service_healthy` gate on `phoenix` — tracing export is fire-and-forget from the
backend's perspective, so it must not block backend startup if Phoenix is slow to come up.
Reachable at `http://localhost:6006` once the stack is up.

`phoenix` joins the default `docker compose up` stack (not an opt-in profile) — the team wants
tracing on by default, and one extra container is a low cost.

## 7. Testing

- **`tests/test_providers.py`**: remove `BedrockProvider` import and `test_get_llm_provider_bedrock`.
  Add a test asserting `OpenRouterProvider()` builds an `AsyncOpenAI` client with
  `base_url="https://openrouter.ai/api/v1"` and picks up `OPENROUTER_MODEL`/`OPENROUTER_API_KEY`
  from the environment (default model falls back to `openai/gpt-4o-mini`).
- **New `tests/test_llm_provider.py`**: monkeypatches `AsyncOpenAI.chat.completions.create` (via
  `unittest.mock.AsyncMock`) to return a canned `ChatCompletion`-shaped object; asserts
  `OpenRouterProvider.chat()` sends the system prompt as the first message, forwards the rest of
  `messages` unchanged, and returns `response.choices[0].message.content`. Fully offline — no real
  API key or network call.
- **`tests/test_fda_router.py`**: new test for `GET /fda/drug/{name}` using `FDA_PROVIDER=fixture`
  + `LLM_PROVIDER=mock` (mirrors the existing `test_ai_router.py` convention of monkeypatching
  `LLM_PROVIDER`) — asserts the response body has `drug_name`, `summary`, and `source == "fixture"`.
- **New `tests/test_observability.py`**: asserts `setup_tracing()` is a true no-op (doesn't raise,
  doesn't import `phoenix`/`openinference`) when `PHOENIX_COLLECTOR_ENDPOINT` is unset; asserts
  `register()` and `OpenAIInstrumentor().instrument()` are both invoked (mocked, no real network)
  when the env var is set.
- Full existing suite (32 tests) must stay green, unchanged. Final acceptance step: run
  `cd backend && python -m pytest -v` and confirm all pass (existing 32 + new tests from this
  change) with zero failures/errors — this is the concrete check-off for "make sure all python
  tests work correctly."

## 8. Docs & config cleanup

- `backend/requirements.txt`: add `openai`, `arize-phoenix-otel`, `openinference-instrumentation-openai`.
- `.env.example`: drop the `bedrock` mention from the `LLM_PROVIDER` comment (`mock \| openrouter`
  only); document `PHOENIX_COLLECTOR_ENDPOINT` and `PHOENIX_PROJECT_NAME`.
- `README.md`: update the provider table (drop the Bedrock half of the AI row); add a short
  "Observability" section pointing at `http://localhost:6006` for the Phoenix UI.

## 9. Out of scope / explicitly flagged, not decided here

- `docs/PLAN.md` (the original AWS-hackathon strategy doc) pitches Bedrock as one of the "five to
  six AWS services" in the submission narrative. This design does not edit that doc — it's a
  planning/pitch artifact, not code — but dropping Bedrock from the actual implementation may
  warrant revisiting that pitch line separately, outside this change.
- FDA warnings queue/approve/dismiss/refresh: unchanged, no LLM call added there.
- Cognito auth: unrelated, untouched.
- CI/CD, Terraform/CDK: unrelated, untouched.

## 10. Decision log (from clarifying questions during design)

1. **FDA scope**: add real LLM summarization to `GET /fda/drug/{name}` now, rather than only
   simplifying the provider factory — closes the gap between `docs/PLAN.md`'s original FDA-panel
   scope and what's actually implemented.
2. **LLM client**: use the `openai` SDK against OpenRouter (OpenAI-API-compatible) plus
   OpenInference's `openinference-instrumentation-openai` auto-instrumentation, over hand-rolled
   `httpx` + manual OTel spans — far less code, and token/prompt capture comes for free.
3. **Test isolation**: mock the OpenAI client and no-op tracing in tests (gated on
   `PHOENIX_COLLECTOR_ENDPOINT` being unset) rather than skip-if-Phoenix-is-up — keeps the full
   suite offline, fast, and deterministic like today's `MockLLMProvider`-based tests.
4. **Phoenix in compose**: always-on part of the default stack, not an opt-in profile.
