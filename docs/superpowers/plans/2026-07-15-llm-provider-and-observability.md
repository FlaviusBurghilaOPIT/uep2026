# LLM Provider Consolidation & Phoenix Observability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the unimplemented `BedrockProvider`, implement `OpenRouterProvider` for real, add LLM summarization to the FDA drug-lookup endpoint, and trace both LLM call sites (prompts, outputs, token usage) to an Arize Phoenix service in docker-compose.

**Architecture:** All changes flow through the existing provider-factory seam (`backend/app/providers/`). The `openai` SDK pointed at OpenRouter's OpenAI-compatible endpoint gives us OpenInference auto-instrumentation for free; a single `setup_tracing()` gate in a new `app/observability.py` no-ops unless `PHOENIX_COLLECTOR_ENDPOINT` is set (compose sets it; pytest doesn't).

**Tech Stack:** Python 3.11/3.12, FastAPI, `openai` SDK (~2.45), `arize-phoenix-otel` (~0.16), `openinference-instrumentation-openai` (~0.1.52), pytest, Docker Compose, `arizephoenix/phoenix` image.

**Spec:** `docs/superpowers/specs/2026-07-15-llm-provider-and-observability-design.md`

## Global Constraints

- Tests must pass fully offline: no real OpenRouter key, no Phoenix container, no network. Real LLM calls are mocked via `unittest.mock.AsyncMock`; tracing setup is gated on `PHOENIX_COLLECTOR_ENDPOINT` which pytest never sets.
- The `/ai/chat` request/response contract is unchanged. The FDA warnings queue endpoints (`/fda/warnings*`) are unchanged.
- `LLM_PROVIDER` accepts only `mock` (default) and `openrouter` after this change — every `bedrock` mention in code, tests, `.env.example`, and `README.md` is removed. `docs/PLAN.md` (pitch doc) is intentionally NOT edited.
- Follow existing code style: `black`/`ruff` with line-length 100 (config in `backend/pyproject.toml`), no docstrings in routers, multi-line `Depends(...)` args.
- Working directory for all backend commands: `/Users/flavius/OPIT/git/uep2026/backend`. Postgres from the dev compose stack must be up for the full-suite run (RLS tests need `localhost:5432`; `tests/conftest.py` defaults the URL).
- Verified library facts (do not re-derive): `phoenix.otel.register()` takes `project_name=` and reads `PHOENIX_COLLECTOR_ENDPOINT` from the environment on its own; `OpenAIInstrumentor().instrument(tracer_provider=...)` is the instrumentation entry point; `using_attributes(session_id=..., metadata=...)` imports from `openinference.instrumentation`; the `openai` `AsyncOpenAI` constructor raises `OpenAIError` if it resolves no API key, and it normalizes `base_url` to end with a trailing slash.

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `backend/requirements.txt` | Modify | add `openai`, `arize-phoenix-otel`, `openinference-instrumentation-openai` |
| `backend/app/providers/llm.py` | Modify | delete `BedrockProvider`; real `OpenRouterProvider` via `AsyncOpenAI` |
| `backend/tests/test_providers.py` | Modify | drop bedrock test; fix openrouter factory test to set a fake key |
| `backend/tests/test_llm_provider.py` | Create | offline tests for `OpenRouterProvider.chat()` message assembly + client config |
| `backend/app/providers/fda.py` | Modify | add `source` class attribute to both providers |
| `backend/app/schemas.py` | Modify | add `FDADrugInfoResponse` |
| `backend/app/routers/fda.py` | Modify | `GET /fda/drug/{name}` gains LLM summarization step |
| `backend/tests/test_fda_router.py` | Modify | new test for the summarized drug-info response |
| `backend/app/observability.py` | Create | `setup_tracing()` — the only tracing-aware module |
| `backend/app/main.py` | Modify | call `setup_tracing()` once at startup; refresh the `fda` tag description |
| `backend/app/routers/ai.py` | Modify | wrap LLM call in `using_attributes(...)` |
| `backend/tests/test_observability.py` | Create | no-op-without-endpoint + registers-when-set tests |
| `docker-compose.yml` | Modify | `phoenix` service, `phoenix_data` volume, backend env + depends_on |
| `.env.example` | Modify | drop bedrock mention; document Phoenix vars |
| `README.md` | Modify | provider table update; new Observability section |
| `docs/superpowers/specs/2026-07-15-llm-provider-and-observability-design.md` | Modify | correct collector endpoint port 4317 → 6006 (verified against docs) |

---

### Task 1: Real OpenRouterProvider, Bedrock removed

**Files:**
- Modify: `backend/requirements.txt`
- Modify: `backend/app/providers/llm.py`
- Modify: `backend/tests/test_providers.py`
- Create: `backend/tests/test_llm_provider.py`

**Interfaces:**
- Consumes: env vars `OPENROUTER_API_KEY`, `OPENROUTER_MODEL`, `LLM_PROVIDER`.
- Produces: `OpenRouterProvider` with `self._client: AsyncOpenAI` and `self._model: str` attributes (Task 1's own tests reach into `_client`/`_model`; nothing else does), and `async chat(messages: list[dict], system: str) -> str` returning `response.choices[0].message.content`. `get_llm_provider()` now returns only `MockLLMProvider` or `OpenRouterProvider`. `BedrockProvider` no longer exists — later tasks must not reference it.

- [ ] **Step 1: Add the three new dependencies**

In `backend/requirements.txt`, append after the `bcrypt<4.1` line (keeping test/dev tools at the bottom):

```
openai
arize-phoenix-otel
openinference-instrumentation-openai
```

- [ ] **Step 2: Install them**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && pip install -r requirements.txt`
Expected: successful install of `openai`, `arize-phoenix-otel`, `openinference-instrumentation-openai` and their OpenTelemetry dependencies, no errors. (There is a known harmless `RequestsDependencyWarning` about urllib3/chardet in this environment — ignore it.)

- [ ] **Step 3: Write the failing tests for the real provider**

Create `backend/tests/test_llm_provider.py`:

```python
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
```

- [ ] **Step 4: Run them to verify they fail**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_llm_provider.py -v`
Expected: 2 FAILED — `OpenRouterProvider` has no `_client` attribute (its `__init__` doesn't exist yet; `chat()` is a `pass` stub).

- [ ] **Step 5: Implement the provider (and delete Bedrock)**

Replace `backend/app/providers/llm.py` in full:

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

No try/except around the OpenRouter call — consistent with `LiveFDAProvider`, failures propagate as FastAPI 500s (spec §3).

- [ ] **Step 6: Update test_providers.py — drop bedrock, fix the openrouter factory test**

In `backend/tests/test_providers.py`:

Change the import line

```python
from app.providers.llm import BedrockProvider, MockLLMProvider, OpenRouterProvider, get_llm_provider
```

to

```python
from app.providers.llm import MockLLMProvider, OpenRouterProvider, get_llm_provider
```

Change `test_get_llm_provider_openrouter` (constructing the real provider now requires a key — `AsyncOpenAI` raises `OpenAIError` when it resolves none):

```python
def test_get_llm_provider_openrouter(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openrouter")
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-key")
    assert isinstance(get_llm_provider(), OpenRouterProvider)
```

Delete this test entirely:

```python
def test_get_llm_provider_bedrock(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "bedrock")
    assert isinstance(get_llm_provider(), BedrockProvider)
```

- [ ] **Step 7: Run both provider test files to verify green**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_llm_provider.py tests/test_providers.py -v`
Expected: 9 passed (2 new + 7 remaining in test_providers.py), 0 failed.

- [ ] **Step 8: Run the full suite to confirm no collateral damage**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest -v`
Expected: 33 passed (was 32: −1 bedrock test, +2 new). `test_ai_router.py` still passes because it monkeypatches `LLM_PROVIDER=mock`.

- [ ] **Step 9: Commit**

```bash
cd /Users/flavius/OPIT/git/uep2026 && git add backend/requirements.txt backend/app/providers/llm.py backend/tests/test_providers.py backend/tests/test_llm_provider.py && git commit -m "feat: implement OpenRouterProvider for real, remove Bedrock stub

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: FDA drug lookup gains LLM summarization

**Files:**
- Modify: `backend/app/providers/fda.py`
- Modify: `backend/app/schemas.py`
- Modify: `backend/app/routers/fda.py:1-17` (imports + `get_drug_info` only — warnings endpoints untouched)
- Modify: `backend/app/main.py:80-84` (the `fda` openapi tag description only)
- Modify: `backend/tests/test_fda_router.py`

**Interfaces:**
- Consumes: `get_llm_provider()` from Task 1 (`await llm.chat(messages=..., system=...) -> str`); `MockLLMProvider`'s exact canned reply string `"This is a mock AI response. The real AI will answer here."` (asserted in the test); existing helpers `_make_clinician(db_session)` and `_auth_headers(user)` already defined at the top of `tests/test_fda_router.py`.
- Produces: `FDAProvider.source: str` class attribute (`"live"` / `"fixture"`); `schemas.FDADrugInfoResponse(drug_name: str, summary: str, source: str)`; `GET /fda/drug/{name}` returning that schema. Task 3 wraps this endpoint's `llm.chat` call in `using_attributes` — keep the call on its own statement so the wrap is a one-line change.

- [ ] **Step 1: Write the failing test**

Append to `backend/tests/test_fda_router.py` (it already imports `models` and defines `_make_clinician` / `_auth_headers`):

```python
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
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_fda_router.py::test_drug_info_returns_llm_summary_with_source -v`
Expected: FAIL — response body is the raw fixture dict (`{"drug": ..., "warnings": [...], "source": "fixture"}`), so `body["drug_name"]` raises `KeyError` / assertion fails.

- [ ] **Step 3: Add the `source` attribute to the FDA providers**

In `backend/app/providers/fda.py`, change the three class headers (bodies unchanged):

```python
class FDAProvider(ABC):
    source: str

    @abstractmethod
    async def get_drug_info(self, drug_name: str) -> dict:
        pass


class LiveFDAProvider(FDAProvider):
    source = "live"

    async def get_drug_info(self, drug_name: str) -> dict:
        ...  # existing body unchanged


class FixtureFDAProvider(FDAProvider):
    source = "fixture"

    async def get_drug_info(self, drug_name: str) -> dict:
        ...  # existing body unchanged
```

(`...` above means "keep the current body exactly as is" — only the `source = ` lines and the ABC annotation are new.)

- [ ] **Step 4: Add the response schema**

In `backend/app/schemas.py`, insert directly above the `FDAWarningResponse` class (line ~103):

```python
class FDADrugInfoResponse(BaseModel):
    drug_name: str
    summary: str
    source: str
```

(No `Config`/`from_attributes` needed — it's constructed explicitly, not from an ORM object.)

- [ ] **Step 5: Rewire the endpoint**

In `backend/app/routers/fda.py`, add to the imports block at the top:

```python
import json

from app.providers.llm import get_llm_provider
```

(`json` goes first as a stdlib import; the provider import joins the existing `from app.providers.fda import get_fda_provider` group. `ruff`'s isort rule will flag wrong ordering — stdlib, then third-party, then `app.*`.)

Add the system prompt constant after `router = APIRouter(...)`:

```python
FDA_SUMMARY_SYSTEM_PROMPT = (
    "You are a patient-facing drug safety summarizer. Given raw openFDA label data, "
    "produce a short, plain-language summary of key warnings and safety information. "
    "You are strictly informational: never advise changing a dose, never diagnose. "
    "If the data is sparse or missing, say so plainly rather than guessing."
)
```

Replace the `get_drug_info` route function (currently `backend/app/routers/fda.py:14-17`):

```python
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

All other routes in the file are untouched.

- [ ] **Step 6: Refresh the stale openapi tag description**

In `backend/app/main.py`, the `fda` tag entry currently reads `"Provides openFDA drug safety lookup for medications (live implementation pending)."` Change that string to:

```python
            "description": (
                "openFDA drug safety lookup with plain-language LLM summaries, "
                "plus the clinician warnings review queue."
            ),
```

- [ ] **Step 7: Run the FDA tests to verify green**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_fda_router.py -v`
Expected: 7 passed (6 existing + 1 new).

- [ ] **Step 8: Run the full suite**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest -v`
Expected: 34 passed.

- [ ] **Step 9: Commit**

```bash
cd /Users/flavius/OPIT/git/uep2026 && git add backend/app/providers/fda.py backend/app/schemas.py backend/app/routers/fda.py backend/app/main.py backend/tests/test_fda_router.py && git commit -m "feat: LLM plain-language summary for FDA drug lookups

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Observability module + call-site trace attributes

**Files:**
- Create: `backend/app/observability.py`
- Create: `backend/tests/test_observability.py`
- Modify: `backend/app/main.py` (one import + one call)
- Modify: `backend/app/routers/ai.py:79-84` (wrap the LLM call)
- Modify: `backend/app/routers/fda.py` (wrap the LLM call added in Task 2)

**Interfaces:**
- Consumes: env vars `PHOENIX_COLLECTOR_ENDPOINT`, `PHOENIX_PROJECT_NAME`; `phoenix.otel.register(project_name=...)` (reads the collector endpoint env var itself — do NOT pass an `endpoint=` kwarg); `openinference.instrumentation.openai.OpenAIInstrumentor().instrument(tracer_provider=...)`; `openinference.instrumentation.using_attributes(session_id=..., metadata=...)`.
- Produces: `app.observability.setup_tracing() -> None` — called exactly once, from `app/main.py`. It must import phoenix/openinference **inside the function, after the env check**, so pytest (no env var) never pays the import and the two mock-based tests can patch the module attributes before the from-import resolves them at call time.

- [ ] **Step 1: Write the failing tests**

Create `backend/tests/test_observability.py`:

```python
from unittest.mock import MagicMock

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
```

(The monkeypatching works precisely because `setup_tracing` does its `from phoenix.otel import register` at call time — it resolves the patched module attribute. This is why the deferred import is a hard requirement, not a style choice.)

- [ ] **Step 2: Run them to verify they fail**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_observability.py -v`
Expected: FAIL at collection with `ModuleNotFoundError: No module named 'app.observability'`.

- [ ] **Step 3: Implement the module**

Create `backend/app/observability.py`:

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

`register()` picks up `PHOENIX_COLLECTOR_ENDPOINT` from the environment itself; default (non-batch) span processing exports immediately, which is what we want for a dev/demo stack.

- [ ] **Step 4: Run the observability tests to verify green**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_observability.py -v`
Expected: 2 passed.

- [ ] **Step 5: Call it at startup**

In `backend/app/main.py`, add to the imports (after `from app.dependencies import get_current_user`):

```python
from app.observability import setup_tracing
```

and immediately after the closing `)` of the `app = FastAPI(...)` call (currently line 90), add:

```python
setup_tracing()
```

- [ ] **Step 6: Tag the AI chat call site**

In `backend/app/routers/ai.py`, add to the imports:

```python
from openinference.instrumentation import using_attributes
```

and change the LLM call in the `chat` route (currently lines 79-84):

```python
    else:
        provider = get_llm_provider()
        system_prompt = _build_system_prompt(case)
        with using_attributes(session_id=case.id, metadata={"endpoint": "ai.chat"}):
            reply = await provider.chat(
                messages=[{"role": "user", "content": request.message}],
                system=system_prompt,
            )
```

(`using_attributes` is a contextvar-based no-op when no tracer is configured — safe in tests and in local runs without Phoenix.)

- [ ] **Step 7: Tag the FDA summarize call site**

In `backend/app/routers/fda.py`, add to the imports:

```python
from openinference.instrumentation import using_attributes
```

and in `get_drug_info`, wrap the `llm.chat` call from Task 2:

```python
    llm = get_llm_provider()
    with using_attributes(metadata={"endpoint": "fda.summarize", "drug_name": name}):
        summary = await llm.chat(
            messages=[{"role": "user", "content": json.dumps(raw)[:4000]}],
            system=FDA_SUMMARY_SYSTEM_PROMPT,
        )
```

- [ ] **Step 8: Run the full suite**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest -v`
Expected: 36 passed (34 + 2 observability). The `ai`/`fda` router tests confirm the `using_attributes` wraps changed no behavior.

- [ ] **Step 9: Commit**

```bash
cd /Users/flavius/OPIT/git/uep2026 && git add backend/app/observability.py backend/tests/test_observability.py backend/app/main.py backend/app/routers/ai.py backend/app/routers/fda.py && git commit -m "feat: Arize Phoenix LLM tracing, gated on PHOENIX_COLLECTOR_ENDPOINT

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: docker-compose Phoenix service, docs, and final verification

**Files:**
- Modify: `docker-compose.yml`
- Modify: `.env.example`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-07-15-llm-provider-and-observability-design.md` (one-line port correction)

**Interfaces:**
- Consumes: `setup_tracing()`'s env gate from Task 3 — compose enables tracing purely by setting `PHOENIX_COLLECTOR_ENDPOINT` on the backend service.
- Produces: a `phoenix` service in the default stack; Phoenix UI on `http://localhost:6006`.

- [ ] **Step 1: Add the phoenix service and wire the backend**

In `docker-compose.yml`, insert the `phoenix` service between the `db` and `backend` services:

```yaml
  # LLM observability — traces prompts, outputs, and token usage from the backend
  phoenix:
    image: arizephoenix/phoenix:latest
    ports:
      - "6006:6006" # UI + OTLP http
      - "4317:4317" # OTLP grpc
    volumes:
      - phoenix_data:/mnt/data
```

In the `backend` service, add an `environment` block and extend `depends_on` (keep the existing mapping form — mixing list and mapping forms in one `depends_on` is a compose error):

```yaml
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    env_file: .env
    environment:
      PHOENIX_COLLECTOR_ENDPOINT: http://phoenix:6006
    depends_on:
      db:
        condition: service_healthy
      phoenix:
        condition: service_started
    volumes:
      - ./backend:/app
    command: sh -c "DATABASE_URL=$$MIGRATION_DATABASE_URL alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
```

(`service_started`, not `service_healthy` — tracing export is fire-and-forget; the backend must not be blocked by Phoenix startup. `environment` overrides `env_file`, so `.env` needs no Phoenix entry.)

Add `phoenix_data` to the top-level volumes block:

```yaml
volumes:
  pgdata:
  phoenix_data:
```

- [ ] **Step 2: Validate compose syntax**

Run: `cd /Users/flavius/OPIT/git/uep2026 && docker compose config --quiet`
Expected: no output, exit code 0.

- [ ] **Step 3: Update .env.example**

In `.env.example`, change the AI comment block

```
# AI
# mock = canned response, no external call (default)
# openrouter / bedrock = real LLM calls, require the matching credentials
```

to

```
# AI
# mock = canned response, no external call (default)
# openrouter = real LLM calls via OpenRouter, requires OPENROUTER_API_KEY
```

and append at the end of the file:

```
# Observability
# LLM tracing (prompts, outputs, token usage) via Arize Phoenix.
# docker-compose sets PHOENIX_COLLECTOR_ENDPOINT on the backend service itself;
# only set it here if you run the backend outside compose. Unset = tracing off.
# PHOENIX_COLLECTOR_ENDPOINT=http://localhost:6006
PHOENIX_PROJECT_NAME=remote-carepro
```

- [ ] **Step 4: Update the README**

In `README.md`:

(a) Change the AI row of the provider table from

```markdown
| AI | `LLM_PROVIDER` | `mock` — canned response | `openrouter` / `bedrock` |
```

to

```markdown
| AI | `LLM_PROVIDER` | `mock` — canned response | `openrouter` — real LLM calls (needs `OPENROUTER_API_KEY`) |
```

(b) Insert a new section between "Local development" and "Tests":

```markdown
## Observability

Every LLM call (the `/ai/chat` assistant and the `/fda/drug/{name}` plain-language
safety summary) is traced with [Arize Phoenix](https://phoenix.arize.com): system
prompt, full input messages, output, token usage (prompt/completion/total), model,
latency, and errors. The `phoenix` service is part of the default compose stack —
UI at `http://localhost:6006`.

Tracing is gated on `PHOENIX_COLLECTOR_ENDPOINT` (docker-compose sets it on the
backend service). When it's unset — plain `pytest` runs, or running uvicorn
locally without Phoenix — tracing setup is skipped entirely and no spans are
exported. Traces are tagged with a per-case `session_id` (chat) and an `endpoint`
metadata key (`ai.chat` / `fda.summarize`) for filtering in the Phoenix UI.
```

(c) In the "Local development" paragraph that lists what `docker compose up -d --build` starts, extend the sentence listing services to mention Phoenix, e.g. change "and a Prism mock server for the OpenAPI contract" to "a Prism mock server for the OpenAPI contract, and an Arize Phoenix trace collector/UI (`http://localhost:6006`)".

- [ ] **Step 5: Correct the spec's collector port**

In `docs/superpowers/specs/2026-07-15-llm-provider-and-observability-design.md`, §6, change

```yaml
      PHOENIX_COLLECTOR_ENDPOINT: http://phoenix:4317
```

to

```yaml
      PHOENIX_COLLECTOR_ENDPOINT: http://phoenix:6006
```

(Verified during planning: `phoenix.otel.register()` documents `http://host:6006` as the collector endpoint form and reads the env var itself; 4317 is only the raw gRPC port, which stays exposed for other OTLP producers.)

- [ ] **Step 6: Full-suite verification (the "all python tests work" acceptance gate)**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest -v`
Expected: **36 passed, 0 failed** (32 original − 1 bedrock + 2 llm_provider + 1 fda summary + 2 observability). The RLS test needs the compose Postgres on `localhost:5432` — start it with `docker compose up -d db` if it isn't running.

- [ ] **Step 7: Live-stack smoke test (requires Docker)**

Run:
```bash
cd /Users/flavius/OPIT/git/uep2026 && docker compose up -d --build && sleep 10 && curl -s http://localhost:8000/health/db && curl -s -o /dev/null -w "%{http_code}" http://localhost:6006
```
Expected: `{"database":"connected"}` followed by `200` (Phoenix UI answering). Then confirm the backend booted tracing without errors: `docker compose logs backend | tail -20` shows uvicorn running, no Python tracebacks mentioning `phoenix` or `openinference`.

- [ ] **Step 8: Commit**

```bash
cd /Users/flavius/OPIT/git/uep2026 && git add docker-compose.yml .env.example README.md docs/superpowers/specs/2026-07-15-llm-provider-and-observability-design.md && git commit -m "feat: Phoenix service in compose stack; docs for LLM observability

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

## Self-Review Notes

- **Spec coverage:** §3 provider consolidation → Task 1; §4 FDA summarization (source attr, schema, endpoint, prompt) → Task 2; §5 observability module, main.py wiring, `using_attributes` at both call sites → Task 3; §6 compose (always-on, no health gate, both ports, volume) → Task 4; §7 testing (all five bullets) → Tasks 1–4 test steps; §8 docs/config cleanup → Task 4 steps 3–4; §9 out-of-scope respected (no PLAN.md edit, warnings endpoints untouched). The one spec deviation — collector port 6006 instead of 4317 — is deliberate, verified against Phoenix docs, and Task 4 Step 5 back-corrects the spec.
- **Type consistency:** `chat(messages: list[dict], system: str) -> str` used identically in Tasks 1–3; `FDADrugInfoResponse` field names match between schema (Task 2 Step 4), endpoint return (Step 5), and test (Step 1); `setup_tracing()` signature matches between module, main.py call, and both tests.
- **Test count arithmetic:** 32 → 33 (Task 1) → 34 (Task 2) → 36 (Task 3), asserted at each task's full-suite step.
