# Structured Medication Scheduling & Language-Agnostic Guardrails — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace free-text schedule parsing and English-only AI guardrails with a structured frequency enum contract that works correctly under i18n.

**Architecture:** The clinician selects a frequency code (QD/BID/TID/QID/PRN) from a dropdown; the backend stores the code and uses a pure lookup table to generate reminders; the mobile app maps the code to a localized label. The AI guardrail replaces English keyword matching with a typed `intent_category` enum sent by the frontend, with Bedrock as the authoritative semantic safety layer.

**Tech Stack:** Python 3.11 / FastAPI / Pydantic v2 / SQLAlchemy · React 18 / TypeScript · Flutter 3 / Dart / Riverpod · ARB l10n

## Global Constraints

- `Medication.schedule_text` DB column is NOT renamed or migrated — router writes canonical code into it
- `FrequencyCode` values are uppercase Latin abbreviations: `QD`, `BID`, `TID`, `QID`, `PRN` — never translated
- `parse_schedule_text` function is deleted; `parse_duration_days` is kept unchanged
- `OUT_OF_SCOPE_MARKERS` list and `OUT_OF_SCOPE_REGEX` are deleted — no English keyword matching survives
- All existing passing tests must continue to pass after each task
- Run `python3 -m pytest tests -q` from `backend/` directory
- Run `npm run build && npm run lint` from `web/` directory
- Run `flutter analyze` from `mobile/` directory

---

### Task 1: Backend — FrequencyCode enum + schedule_parser rewrite

**Files:**
- Modify: `backend/app/schemas.py` (add `FrequencyCode`, `IntentCategory` enums; update `MedicationCreate`, `MedicationResponse`, `ChatRequest`)
- Modify: `backend/app/services/schedule_parser.py` (full rewrite — delete regex, add lookup table)
- Modify: `backend/app/routers/cases.py` (write `frequency.value` into `schedule_text`)
- Modify: `backend/tests/test_medications_router.py` (update tests to use `frequency` field)

**Interfaces:**
- Produces: `FrequencyCode` enum with values `QD|BID|TID|QID|PRN`; `times_for_frequency(frequency: str) -> list[time]`; `FREQUENCY_TIMES: Final[dict[str, list[time]]]`
- Produces: `MedicationCreate.frequency: FrequencyCode` (replaces `schedule_text`)
- Produces: `MedicationResponse.frequency: FrequencyCode`, `MedicationResponse.schedule_times: list[str]`

- [ ] **Step 1: Write failing tests for new parser**

In `backend/tests/test_medications_router.py`, replace the current `test_parse_schedule_text_variations` test and update the POST tests. Replace the entire file with:

```python
from datetime import time
from app import models
from app.security import create_access_token
from app.services.schedule_parser import times_for_frequency, parse_duration_days


def test_times_for_frequency_all_codes():
    assert times_for_frequency("QD")  == [time(8, 0)]
    assert times_for_frequency("BID") == [time(8, 0), time(20, 0)]
    assert times_for_frequency("TID") == [time(8, 0), time(13, 0), time(20, 0)]
    assert times_for_frequency("QID") == [time(8, 0), time(12, 0), time(16, 0), time(20, 0)]
    assert times_for_frequency("PRN") == []


def test_times_for_frequency_case_insensitive():
    assert times_for_frequency("tid") == [time(8, 0), time(13, 0), time(20, 0)]
    assert times_for_frequency("Bid") == [time(8, 0), time(20, 0)]


def test_times_for_frequency_unknown_defaults_to_qd():
    assert times_for_frequency("UNKNOWN") == [time(8, 0)]


def test_parse_duration_days_variations():
    assert parse_duration_days("7 days") == 7
    assert parse_duration_days("10 days") == 10
    assert parse_duration_days("2 weeks") == 14
    assert parse_duration_days("1 week") == 7
    assert parse_duration_days("5") == 5
    assert parse_duration_days(None) == 7
    assert parse_duration_days("") == 7
    assert parse_duration_days("until finished") == 7


def _make_clinician_patient_case(db_session, suffix=""):
    clinician = models.User(
        email=f"doctor{suffix}@example.com",
        full_name=f"Dr. House{suffix}",
        role=models.UserRole.clinician,
    )
    patient = models.User(
        email=f"patient{suffix}@example.com",
        full_name=f"Patient{suffix}",
        role=models.UserRole.patient,
    )
    db_session.add_all([clinician, patient])
    db_session.commit()
    case = models.Case(
        clinician_id=clinician.id,
        patient_id=patient.id,
        surgery_type="ACL Repair",
    )
    db_session.add(case)
    db_session.commit()
    token = create_access_token(
        {"sub": clinician.id, "role": "clinician", "email": clinician.email}
    )
    return clinician, patient, case, token


def test_create_medication_tid_7days_generates_21_reminders(client, db_session):
    _, _, case, token = _make_clinician_patient_case(db_session, "1")
    payload = {
        "name": "Ibuprofen",
        "dose": "400mg",
        "frequency": "TID",
        "duration": "7 days",
        "notes": "Take with food",
    }
    response = client.post(
        f"/cases/{case.id}/medications",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    med_data = response.json()
    assert med_data["name"] == "Ibuprofen"
    assert med_data["frequency"] == "TID"
    assert med_data["schedule_times"] == ["08:00", "13:00", "20:00"]
    assert len(med_data["scheduled_reminders"]) == 21
    assert med_data["scheduled_reminders"][0]["status"] == "pending"
    assert "08:00:00" in med_data["scheduled_reminders"][0]["scheduled_time"]


def test_create_medication_bid_2weeks_generates_28_reminders(client, db_session):
    _, _, case, token = _make_clinician_patient_case(db_session, "2")
    payload = {
        "name": "Paracetamol",
        "dose": "500mg",
        "frequency": "BID",
        "duration": "2 weeks",
    }
    response = client.post(
        f"/cases/{case.id}/medications",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    med_data = response.json()
    assert len(med_data["scheduled_reminders"]) == 28
    assert med_data["schedule_times"] == ["08:00", "20:00"]


def test_create_medication_prn_generates_zero_reminders(client, db_session):
    _, _, case, token = _make_clinician_patient_case(db_session, "3")
    payload = {
        "name": "Tramadol",
        "dose": "50mg",
        "frequency": "PRN",
        "duration": "7 days",
    }
    response = client.post(
        f"/cases/{case.id}/medications",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    med_data = response.json()
    assert med_data["scheduled_reminders"] == []
    assert med_data["schedule_times"] == []


def test_create_medication_invalid_frequency_rejected(client, db_session):
    _, _, case, token = _make_clinician_patient_case(db_session, "4")
    payload = {
        "name": "Aspirin",
        "dose": "100mg",
        "frequency": "3x daily",   # invalid — must be enum code
        "duration": "7 days",
    }
    response = client.post(
        f"/cases/{case.id}/medications",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 422   # Pydantic validation error
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd backend && python3 -m pytest tests/test_medications_router.py -v
```

Expected: FAIL — `ImportError: cannot import name 'times_for_frequency'` and `422` tests fail because schema still uses `schedule_text`.

- [ ] **Step 3: Rewrite `backend/app/services/schedule_parser.py`**

Replace entire file content:

```python
from datetime import datetime, time, timedelta
from typing import Final
import re
from sqlalchemy.orm import Session
from app import models


FREQUENCY_TIMES: Final[dict[str, list[time]]] = {
    "QD":  [time(8, 0)],
    "BID": [time(8, 0), time(20, 0)],
    "TID": [time(8, 0), time(13, 0), time(20, 0)],
    "QID": [time(8, 0), time(12, 0), time(16, 0), time(20, 0)],
    "PRN": [],
}


def times_for_frequency(frequency: str) -> list[time]:
    """Returns default UTC reminder times for a FrequencyCode. Never raises."""
    return FREQUENCY_TIMES.get(frequency.upper(), [time(8, 0)])


def parse_duration_days(duration: str | None) -> int:
    """
    Parses a duration string to determine total number of days.
    - e.g. '7 days' -> 7
    - e.g. '2 weeks' -> 14
    - Default to 7 days if missing or unparseable.
    """
    if not duration:
        return 7

    st = duration.lower().strip()

    week_match = re.search(r"(\d+)\s*week", st)
    if week_match:
        try:
            return int(week_match.group(1)) * 7
        except ValueError:
            pass

    day_match = re.search(r"(\d+)", st)
    if day_match:
        try:
            val = int(day_match.group(1))
            return val if val > 0 else 7
        except ValueError:
            pass

    return 7


def create_scheduled_reminders_for_medication(
    db: Session, medication: models.Medication
) -> list[models.ScheduledReminder]:
    """
    Generates ScheduledReminder DB records for each day of duration.
    Uses times_for_frequency() — no regex, no language parsing.
    Stores scheduled_time in UTC naive datetime.
    """
    times = times_for_frequency(medication.schedule_text)
    days = parse_duration_days(medication.duration)

    if not times:
        return []   # PRN — no reminders

    start_date = datetime.utcnow().date()
    reminders = []

    for day_offset in range(days):
        day_date = start_date + timedelta(days=day_offset)
        for t in times:
            scheduled_dt = datetime.combine(day_date, t)
            reminder = models.ScheduledReminder(
                medication_id=medication.id,
                scheduled_time=scheduled_dt,
                status="pending",
            )
            db.add(reminder)
            reminders.append(reminder)

    return reminders
```

- [ ] **Step 4: Add `FrequencyCode` enum + update schemas in `backend/app/schemas.py`**

Add after the existing imports block (after line 3 `from pydantic import BaseModel`):

```python
import enum

class FrequencyCode(str, enum.Enum):
    QD  = "QD"
    BID = "BID"
    TID = "TID"
    QID = "QID"
    PRN = "PRN"
```

Replace `MedicationCreate`:

```python
class MedicationCreate(BaseModel):
    name:      str
    dose:      str
    frequency: FrequencyCode
    duration:  str
    notes:     str | None = None
```

Replace `MedicationResponse`:

```python
class MedicationResponse(BaseModel):
    id:             str
    case_id:        str
    name:           str
    dose:           str
    frequency:      FrequencyCode
    schedule_times: list[str] = []
    duration:       str
    notes:          str | None
    created_at:     datetime
    scheduled_reminders: list[ReminderResponse] = []

    class Config:
        from_attributes = True
```

- [ ] **Step 5: Update `backend/app/routers/cases.py` — medication creation endpoint**

In the `create_case_medication` function (around line 116), replace the `new_medication = models.Medication(...)` block:

```python
    new_medication = models.Medication(
        case_id=case_id,
        name=medication.name,
        dose=medication.dose,
        schedule_text=medication.frequency.value,   # store canonical code
        duration=medication.duration,
        notes=medication.notes,
    )
```

After `db.refresh(new_medication)` and before `return new_medication`, add `schedule_times` computation. Since `MedicationResponse` is a Pydantic model with `from_attributes=True`, we need the router to return a response with `schedule_times`. Update the return to use `jsonable_encoder` or a manual response:

Replace the final `return new_medication` with:

```python
    from app.services.schedule_parser import FREQUENCY_TIMES
    times = FREQUENCY_TIMES.get(new_medication.schedule_text, [])
    schedule_times_str = [t.strftime("%H:%M") for t in times]

    return schemas.MedicationResponse(
        id=new_medication.id,
        case_id=new_medication.case_id,
        name=new_medication.name,
        dose=new_medication.dose,
        frequency=schemas.FrequencyCode(new_medication.schedule_text),
        schedule_times=schedule_times_str,
        duration=new_medication.duration,
        notes=new_medication.notes,
        created_at=new_medication.created_at,
        scheduled_reminders=[
            schemas.ReminderResponse(
                id=r.id,
                medication_id=r.medication_id,
                scheduled_time=r.scheduled_time,
                status=r.status,
                created_at=r.created_at,
            )
            for r in new_medication.scheduled_reminders
        ],
    )
```

Also update the `GET /cases/{case_id}/medications` endpoint to return `MedicationResponse` objects with `schedule_times`. Find the list medications endpoint and wrap each medication:

```python
    from app.services.schedule_parser import FREQUENCY_TIMES
    result = []
    for m in case.medications:
        times = FREQUENCY_TIMES.get(m.schedule_text, [])
        result.append(schemas.MedicationResponse(
            id=m.id,
            case_id=m.case_id,
            name=m.name,
            dose=m.dose,
            frequency=schemas.FrequencyCode(m.schedule_text),
            schedule_times=[t.strftime("%H:%M") for t in times],
            duration=m.duration,
            notes=m.notes,
            created_at=m.created_at,
            scheduled_reminders=[
                schemas.ReminderResponse(
                    id=r.id,
                    medication_id=r.medication_id,
                    scheduled_time=r.scheduled_time,
                    status=r.status,
                    created_at=r.created_at,
                )
                for r in m.scheduled_reminders
            ],
        ))
    return result
```

- [ ] **Step 6: Run all backend tests**

```bash
cd backend && python3 -m pytest tests -q
```

Expected: All tests pass. The `test_medications_router.py` tests now pass with the new schema.

- [ ] **Step 7: Commit Task 1**

```bash
cd backend
git add app/schemas.py app/services/schedule_parser.py app/routers/cases.py tests/test_medications_router.py
git commit -m "feat: structured FrequencyCode enum replaces free-text schedule_text parsing"
```

---

### Task 2: Backend — Language-agnostic AI guardrails

**Files:**
- Modify: `backend/app/schemas.py` (add `IntentCategory` enum; update `ChatRequest`)
- Modify: `backend/app/routers/ai.py` (replace English keyword check with `BLOCKED_INTENTS` enum check)
- Modify: `backend/app/providers/llm.py` (delete `OUT_OF_SCOPE_REGEX` and `_check_local_regex_guardrail`)
- Modify: `backend/tests/test_ai_router.py` (update to use `intent_category` field)
- Modify: `backend/tests/test_llm_provider.py` (remove test for deleted regex guardrail)

**Interfaces:**
- Consumes: `FrequencyCode` from Task 1 (schemas.py already updated)
- Produces: `IntentCategory` enum with values `general_question|medication_query|dose_change_request|diagnosis_request`
- Produces: `ChatRequest.intent_category: IntentCategory = IntentCategory.general_question`

- [ ] **Step 1: Write failing tests for intent_category guardrail**

Replace entire `backend/tests/test_ai_router.py`:

```python
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
            "message": "¿Creo que tengo una infección?",   # Spanish
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd backend && python3 -m pytest tests/test_ai_router.py -v
```

Expected: FAIL — `intent_category` not in schema; `dose_change_request` test fails because it still uses English regex which doesn't match Italian text.

- [ ] **Step 3: Add `IntentCategory` to `backend/app/schemas.py`**

After the `FrequencyCode` enum block added in Task 1, add:

```python
class IntentCategory(str, enum.Enum):
    general_question    = "general_question"
    medication_query    = "medication_query"
    dose_change_request = "dose_change_request"
    diagnosis_request   = "diagnosis_request"
```

Replace `ChatRequest`:

```python
class ChatRequest(BaseModel):
    case_id:         str
    message:         str
    intent_category: IntentCategory = IntentCategory.general_question
```

- [ ] **Step 4: Rewrite guardrail logic in `backend/app/routers/ai.py`**

Replace lines 1–99 entirely:

```python
from fastapi import APIRouter, Depends, HTTPException
from openinference.instrumentation import using_attributes
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user
from app.providers.llm import get_llm_provider

router = APIRouter(prefix="/ai", tags=["ai"])

GUARDRAIL_PREAMBLE = (
    "You are a post-surgery recovery assistant. Answer only using the patient's "
    "prescribed medications and recovery recommendations below. You are strictly "
    "informational: never diagnose, never suggest changing a dose or schedule, and "
    "never recommend a new medication. If asked to do any of those, say you can't "
    "and suggest contacting the clinician or emergency contact."
)

BLOCKED_INTENTS = {
    schemas.IntentCategory.dose_change_request,
    schemas.IntentCategory.diagnosis_request,
}


def _build_system_prompt(case: models.Case) -> str:
    meds = (
        "\n".join(
            f"- {m.name} {m.dose}, {m.schedule_text}, for {m.duration}" for m in case.medications
        )
        or "(no medications on file)"
    )
    recs = "\n".join(f"- {r.text}" for r in case.recommendations) or "(no recommendations on file)"

    return (
        f"{GUARDRAIL_PREAMBLE}\n\n"
        f"Prescribed medications:\n{meds}\n\n"
        f"Recovery recommendations:\n{recs}"
    )


def _check_guardrail(request: schemas.ChatRequest) -> tuple[bool, bool]:
    """Language-agnostic: blocks by intent_category enum, not English text."""
    if request.intent_category in BLOCKED_INTENTS:
        return False, True   # in_scope=False, escalate=True
    return True, False


@router.post("/chat", response_model=schemas.ChatResponse)
async def chat(
    request: schemas.ChatRequest,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    case = db.query(models.Case).filter(models.Case.id == request.case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    in_scope, escalate = _check_guardrail(request)

    db.add(
        models.ChatMessage(
            case_id=case.id,
            role=models.ChatRole.user,
            content=request.message,
            in_scope=in_scope,
            escalate=escalate,
        )
    )
    db.commit()

    if not in_scope:
        reply = (
            "I can't help with changing medication doses or schedules — that's a "
            "clinical decision. Please contact your clinician or use the emergency "
            "contact option for anything urgent."
        )
    else:
        provider = get_llm_provider()
        system_prompt = _build_system_prompt(case)
        with using_attributes(session_id=case.id, metadata={"endpoint": "ai.chat"}):
            reply = await provider.chat(
                messages=[{"role": "user", "content": request.message}],
                system=system_prompt,
            )

    db.add(
        models.ChatMessage(
            case_id=case.id,
            role=models.ChatRole.assistant,
            content=reply,
        )
    )
    db.commit()

    return schemas.ChatResponse(reply=reply, in_scope=in_scope, escalate=escalate)
```

- [ ] **Step 5: Clean up `backend/app/providers/llm.py`** — delete regex and local guardrail method

Replace lines 1–145 entirely:

```python
import os
from abc import ABC, abstractmethod

from openai import AsyncOpenAI

FALLBACK_REFUSAL_RESPONSE = (
    "I can't help with changing medication doses or schedules — that's a "
    "clinical decision. Please contact your clinician or use the emergency "
    "contact option for anything urgent."
)


class LLMProvider(ABC):
    @abstractmethod
    async def chat(self, messages: list[dict], system: str) -> str:
        pass


class MockLLMProvider(LLMProvider):
    async def chat(self, messages: list[dict], system: str) -> str:
        return "This is a mock AI response. The real AI will answer here."


class OpenRouterProvider(LLMProvider):
    def __init__(self):
        self._client = AsyncOpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=os.getenv("OPENROUTER_API_KEY"),
        )
        self._model = os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini")

    async def chat(self, messages: list[dict], system: str) -> str:
        response = await self._client.chat.completions.create(
            model=self._model,
            messages=[{"role": "system", "content": system}, *messages],
        )
        return response.choices[0].message.content or ""


class BedrockProvider(LLMProvider):
    def __init__(
        self,
        guardrail_identifier: str | None = None,
        guardrail_version: str | None = None,
        model_id: str | None = None,
        region_name: str | None = None,
    ):
        self.guardrail_identifier = (
            guardrail_identifier
            or os.getenv("BEDROCK_GUARDRAIL_IDENTIFIER")
            or os.getenv("BEDROCK_GUARDRAIL_ID")
        )
        self.guardrail_version = (
            guardrail_version
            or os.getenv("BEDROCK_GUARDRAIL_VERSION", "1")
        )
        self.model_id = (
            model_id
            or os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-sonnet-20240229-v1:0")
        )
        self.region_name = region_name or os.getenv("AWS_REGION", "us-east-1")

    async def chat(self, messages: list[dict], system: str) -> str:
        try:
            import boto3
            import json

            client = boto3.client("bedrock-runtime", region_name=self.region_name)

            kwargs = {
                "modelId": self.model_id,
                "messages": messages,
                "system": [{"text": system}] if system else [],
            }

            if self.guardrail_identifier:
                kwargs["guardrailConfig"] = {
                    "guardrailIdentifier": self.guardrail_identifier,
                    "guardrailVersion": self.guardrail_version,
                }

            if hasattr(client, "converse"):
                response = client.converse(**kwargs)
                output_message = response.get("output", {}).get("message", {})
                content_blocks = output_message.get("content", [])
                if content_blocks and "text" in content_blocks[0]:
                    return content_blocks[0]["text"]

            body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "system": system,
                "messages": messages,
            }
            invoke_kwargs = {
                "modelId": self.model_id,
                "body": json.dumps(body),
            }
            if self.guardrail_identifier:
                invoke_kwargs["guardrailIdentifier"] = self.guardrail_identifier
                invoke_kwargs["guardrailVersion"] = self.guardrail_version

            response = client.invoke_model(**invoke_kwargs)
            res_body = json.loads(response["body"].read())
            if "content" in res_body and res_body["content"]:
                return res_body["content"][0].get("text", "")
            return ""
        except Exception:
            return "This is a Bedrock AI response."


def get_llm_provider() -> LLMProvider:
    p = os.getenv("LLM_PROVIDER", "mock")
    if p == "openrouter":
        return OpenRouterProvider()
    elif p == "bedrock":
        return BedrockProvider()
    return MockLLMProvider()
```

- [ ] **Step 6: Update `backend/tests/test_llm_provider.py`** — remove the now-deleted regex test

Replace the `test_bedrock_provider_local_regex_fallback` test (lines 76–87) with a test that verifies `BedrockProvider` no longer has a regex method:

```python
def test_bedrock_provider_has_no_local_regex_guardrail():
    from app.providers.llm import BedrockProvider
    provider = BedrockProvider()
    assert not hasattr(provider, "_check_local_regex_guardrail"), (
        "Local regex guardrail was deleted — the intent_category enum is now the guardrail"
    )
```

- [ ] **Step 7: Run all backend tests**

```bash
cd backend && python3 -m pytest tests -q
```

Expected: All tests pass including the new Italian and Spanish guardrail tests.

- [ ] **Step 8: Commit Task 2**

```bash
cd backend
git add app/schemas.py app/routers/ai.py app/providers/llm.py \
        tests/test_ai_router.py tests/test_llm_provider.py
git commit -m "feat: language-agnostic AI guardrails via IntentCategory enum"
```

---

### Task 3: Web — Frequency dropdown + i18n keys

**Files:**
- Modify: `web/src/pages/MedicationsPage.tsx` (replace text input with select + reminder preview)
- Modify: `web/src/i18n/types.ts` (add `MedicationTranslations` interface + update `Translations`)
- Modify: `web/src/i18n/translations/en.ts` (add `medication` section)
- Modify: `web/src/i18n/translations/es.ts` (add `medication` section)
- Modify: `web/src/i18n/translations/it.ts` (add `medication` section)

**Interfaces:**
- Consumes: `FrequencyCode` values `QD|BID|TID|QID|PRN` from Task 1
- Consumes: `useTranslation` hook from `web/src/i18n/useTranslation.ts`
- Produces: `POST /cases/{id}/medications` body with `frequency: string` instead of `schedule_text`

- [ ] **Step 1: Add `MedicationTranslations` to `web/src/i18n/types.ts`**

Add after the `CommonTranslations` interface (before the `Translations` interface):

```ts
export interface MedicationTranslations {
  frequencyLabel:   string
  frequencyQD:      string
  frequencyBID:     string
  frequencyTID:     string
  frequencyQID:     string
  frequencyPRN:     string
  remindersAt:      string
  noReminders:      string
}
```

Update the `Translations` interface to add the new section:

```ts
export interface Translations {
  nav:         NavTranslations
  triage:      TriageTranslations
  patientCard: PatientCardTranslations
  cta:         CtaTranslations
  common:      CommonTranslations
  medication:  MedicationTranslations
}
```

- [ ] **Step 2: Add `medication` section to all three locale files**

**`web/src/i18n/translations/en.ts`** — add before closing `}`:

```ts
  medication: {
    frequencyLabel: 'Frequency',
    frequencyQD:    'Once daily (QD)',
    frequencyBID:   'Twice daily (BID)',
    frequencyTID:   'Three times daily (TID)',
    frequencyQID:   'Four times daily (QID)',
    frequencyPRN:   'As needed (PRN)',
    remindersAt:    '⏰ Reminders at:',
    noReminders:    '⏰ No scheduled reminders (as needed)',
  },
```

**`web/src/i18n/translations/es.ts`** — add before closing `}`:

```ts
  medication: {
    frequencyLabel: 'Frecuencia',
    frequencyQD:    'Una vez al día (QD)',
    frequencyBID:   'Dos veces al día (BID)',
    frequencyTID:   'Tres veces al día (TID)',
    frequencyQID:   'Cuatro veces al día (QID)',
    frequencyPRN:   'Según se necesite (PRN)',
    remindersAt:    '⏰ Recordatorios a las:',
    noReminders:    '⏰ Sin recordatorios programados (según necesidad)',
  },
```

**`web/src/i18n/translations/it.ts`** — add before closing `}`:

```ts
  medication: {
    frequencyLabel: 'Frequenza',
    frequencyQD:    'Una volta al giorno (QD)',
    frequencyBID:   'Due volte al giorno (BID)',
    frequencyTID:   'Tre volte al giorno (TID)',
    frequencyQID:   'Quattro volte al giorno (QID)',
    frequencyPRN:   'Al bisogno (PRN)',
    remindersAt:    '⏰ Promemoria alle:',
    noReminders:    '⏰ Nessun promemoria programmato (al bisogno)',
  },
```

- [ ] **Step 3: Run web build to verify i18n types compile**

```bash
cd web && npm run build
```

Expected: Build fails with TypeScript error `Property 'medication' is missing in type`. This confirms the type check works. We'll fix it in the next step.

- [ ] **Step 4: Replace frequency field in `web/src/pages/MedicationsPage.tsx`**

Replace the entire file. The key changes are:
1. `frequency` state initialized to `'QD'` (a `<select>`)
2. Reminder time preview map
3. POST body uses `frequency` not `schedule_text`
4. `useTranslation` hook for locale-aware labels

Full replacement for the top of the file (state + handlers, lines 1–45):

```tsx
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { apiFetch } from '../api/client'
import { useTranslation } from '../i18n/useTranslation'

const FREQUENCY_TIMES: Record<string, string[]> = {
  QD:  ['08:00'],
  BID: ['08:00', '20:00'],
  TID: ['08:00', '13:00', '20:00'],
  QID: ['08:00', '12:00', '16:00', '20:00'],
  PRN: [],
}

function MedicationsPage() {
  const { caseId = 'case-001' } = useParams<{ caseId: string }>()
  const { translations: t } = useTranslation()
  const [name, setName] = useState('')
  const [dose, setDose] = useState('')
  const [frequency, setFrequency] = useState<'QD'|'BID'|'TID'|'QID'|'PRN'>('QD')
  const [durationDays, setDurationDays] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const reminderTimes = FREQUENCY_TIMES[frequency] ?? []

  const handleSubmit = async () => {
    if (!name || !dose || !durationDays) {
      setError('Please fill in all required fields')
      return
    }
    setLoading(true)
    setError('')
    try {
      await apiFetch(`/cases/${caseId}/medications`, {
        method: 'POST',
        body: JSON.stringify({
          name,
          dose,
          frequency,
          duration: `${durationDays} days`,
          notes,
        }),
      })
      setSuccess(true)
    } catch (err: unknown) {
      setError((err as Error).message || 'Failed to add medication. Please try again.')
    } finally {
      setLoading(false)
    }
  }
```

Replace the frequency form field section (the `<label>` + `<input>` for frequency, previously lines ~120–130) with:

```tsx
        <label style={styles.label} htmlFor="frequency">{t.medication.frequencyLabel}</label>
        <select
          id="frequency"
          style={styles.input}
          value={frequency}
          onChange={(e) => setFrequency(e.target.value as 'QD'|'BID'|'TID'|'QID'|'PRN')}
          aria-describedby={error ? 'form-error' : 'frequency-hint'}
        >
          <option value="QD">{t.medication.frequencyQD}</option>
          <option value="BID">{t.medication.frequencyBID}</option>
          <option value="TID">{t.medication.frequencyTID}</option>
          <option value="QID">{t.medication.frequencyQID}</option>
          <option value="PRN">{t.medication.frequencyPRN}</option>
        </select>
        <p id="frequency-hint" style={{ fontSize: '0.8rem', color: '#64748b', margin: '4px 0 12px' }}>
          {reminderTimes.length > 0
            ? `${t.medication.remindersAt} ${reminderTimes.join(', ')}`
            : t.medication.noReminders}
        </p>
```

- [ ] **Step 5: Run web build + lint**

```bash
cd web && npm run build && npm run lint
```

Expected: 0 errors, 0 warnings.

- [ ] **Step 6: Commit Task 3**

```bash
cd web
git add src/pages/MedicationsPage.tsx src/i18n/types.ts \
        src/i18n/translations/en.ts src/i18n/translations/es.ts \
        src/i18n/translations/it.ts
git commit -m "feat: replace free-text frequency input with structured dropdown + i18n labels"
```

---

### Task 4: Mobile — Frequency model + localized display + intent_category in chat

**Files:**
- Modify: `mobile/lib/features/medications/providers/medications_notifier.dart` (replace `scheduleText` with `frequency` + `scheduleTimes`)
- Modify: `mobile/lib/features/today/today_screen.dart` (replace `schedule_text` display with localized lookup)
- Modify: `mobile/lib/features/today/providers/today_agenda_notifier.dart` (update JSON key)
- Modify: `mobile/lib/features/assistant/providers/chat_assistant_notifier.dart` (add `intent_category` to POST body)
- Modify: `mobile/lib/features/assistant/assistant_screen.dart` (add `_classifyIntent()` method)
- Modify: `mobile/lib/core/l10n/app_en.arb` (add frequency keys)
- Modify: `mobile/lib/core/l10n/app_es.arb`
- Modify: `mobile/lib/core/l10n/app_it.arb`
- Modify: `mobile/lib/core/l10n/app_de.arb`
- Modify: `mobile/lib/core/l10n/app_fr.arb`
- Modify: `mobile/lib/core/l10n/app_localizations_en.dart` (add frequency getter stubs — generated, but needs manual sync)

**Interfaces:**
- Consumes: `frequency: String` field in API response (Task 1)
- Consumes: `schedule_times: List<String>` field in API response (Task 1)
- Produces: `_localizedFrequency(BuildContext context, String code) -> String`
- Produces: `sendMessage(caseId, message, intentCategory)` with `intent_category` in POST body

- [ ] **Step 1: Add frequency ARB keys to all 5 locale ARB files**

**`mobile/lib/core/l10n/app_en.arb`** — add before the closing `}` (after `"medicationsEmptyState"` key):

```json
  ,
  "frequencyQD":  "Once daily",
  "frequencyBID": "Twice daily",
  "frequencyTID": "Three times daily",
  "frequencyQID": "Four times daily",
  "frequencyPRN": "As needed"
```

**`mobile/lib/core/l10n/app_es.arb`** — add before closing `}`:

```json
  ,
  "frequencyQD":  "Una vez al día",
  "frequencyBID": "Dos veces al día",
  "frequencyTID": "Tres veces al día",
  "frequencyQID": "Cuatro veces al día",
  "frequencyPRN": "Según sea necesario"
```

**`mobile/lib/core/l10n/app_it.arb`** — add before closing `}`:

```json
  ,
  "frequencyQD":  "Una volta al giorno",
  "frequencyBID": "Due volte al giorno",
  "frequencyTID": "Tre volte al giorno",
  "frequencyQID": "Quattro volte al giorno",
  "frequencyPRN": "Al bisogno"
```

**`mobile/lib/core/l10n/app_de.arb`** — add before closing `}`:

```json
  ,
  "frequencyQD":  "Einmal täglich",
  "frequencyBID": "Zweimal täglich",
  "frequencyTID": "Dreimal täglich",
  "frequencyQID": "Viermal täglich",
  "frequencyPRN": "Bei Bedarf"
```

**`mobile/lib/core/l10n/app_fr.arb`** — add before closing `}`:

```json
  ,
  "frequencyQD":  "Une fois par jour",
  "frequencyBID": "Deux fois par jour",
  "frequencyTID": "Trois fois par jour",
  "frequencyQID": "Quatre fois par jour",
  "frequencyPRN": "Au besoin"
```

- [ ] **Step 2: Run flutter gen-l10n to regenerate localizations**

```bash
cd mobile && flutter gen-l10n
```

Expected: Regenerates `app_localizations_*.dart` files with `frequencyQD`, `frequencyBID`, `frequencyTID`, `frequencyQID`, `frequencyPRN` getters in all locale classes.

- [ ] **Step 3: Update `mobile/lib/features/medications/providers/medications_notifier.dart`**

Replace the `Medication` class and its `fromJson` factory:

```dart
class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.scheduleTimes,
    required this.duration,
    this.notes,
  });

  final String id;
  final String name;
  final String dose;
  final String frequency;       // "QD" | "BID" | "TID" | "QID" | "PRN"
  final List<String> scheduleTimes;  // ["08:00", "13:00", "20:00"]
  final String duration;
  final String? notes;

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id:            json['id'] as String,
    name:          json['name'] as String,
    dose:          json['dose'] as String,
    frequency:     json['frequency'] as String,
    scheduleTimes: List<String>.from(json['schedule_times'] as List? ?? []),
    duration:      json['duration'] as String,
    notes:         json['notes'] as String?,
  );
}
```

- [ ] **Step 4: Update `mobile/lib/features/today/providers/today_agenda_notifier.dart`**

Find the line with `scheduleText: map['schedule_text'] as String,` (line 100) and replace:

```dart
            scheduleText: map['schedule_text'] as String? ?? 
                          (map['frequency'] as String? ?? 'QD'),
```

Note: `today_agenda_notifier.dart` may use its own inline map type rather than `Medication`. Check and update accordingly — replace any reference to `map['schedule_text']` with `map['frequency'] ?? map['schedule_text'] ?? 'QD'` for graceful backward compat.

- [ ] **Step 5: Add `_localizedFrequency` helper and update `today_screen.dart`**

In `mobile/lib/features/today/today_screen.dart`, find the line:
```dart
'dosage': '${m['dose']} · ${m['schedule_text']}',
```

Replace with:
```dart
'dosage': '${m['dose']} · ${_localizedFrequency(context, (m['frequency'] ?? m['schedule_text'] ?? 'QD') as String)}',
```

Add the helper method to the enclosing widget State class:

```dart
String _localizedFrequency(BuildContext context, String code) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return code;
  switch (code.toUpperCase()) {
    case 'QD':  return l10n.frequencyQD;
    case 'BID': return l10n.frequencyBID;
    case 'TID': return l10n.frequencyTID;
    case 'QID': return l10n.frequencyQID;
    case 'PRN': return l10n.frequencyPRN;
    default:    return code;
  }
}
```

- [ ] **Step 6: Add `_classifyIntent` + update `sendMessage` in `chat_assistant_notifier.dart`**

Add a top-level constant map before the `ChatMessage` class:

```dart
// Client-side intent pre-classification keyword lists per locale-agnostic pattern.
// These tags are sent to the backend as the `intent_category` field.
// The backend enum check is the authoritative guardrail; this is a UX pre-classification only.
const List<String> _doseChangeKeywords = [
  // English
  'double dose', 'extra dose', 'stop taking', 'change dose', 'increase dose', 'decrease dose',
  // Spanish
  'doble dosis', 'dosis extra', 'dejar de tomar', 'cambiar dosis', 'aumentar dosis',
  // Italian
  'doppia dose', 'dose extra', 'smettere di prendere', 'cambiare dose',
  // German
  'doppelte dosis', 'extra dosis', 'aufhören zu nehmen',
  // French
  'double dose', 'arrêter de prendre', 'changer la dose',
];

const List<String> _diagnosisKeywords = [
  'diagnose', 'do i have', 'what disease', 'is this cancer',
  'diagnosticar', 'tengo', 'ho una', 'habe ich', 'j\'ai',
];

String _classifyIntent(String message) {
  final lower = message.toLowerCase();
  if (_doseChangeKeywords.any(lower.contains)) return 'dose_change_request';
  if (_diagnosisKeywords.any(lower.contains)) return 'diagnosis_request';
  return 'general_question';
}
```

Update `sendMessage` to include `intent_category` in the POST body:

```dart
  Future<void> sendMessage({
    required String caseId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    // ... existing userMsg state update code unchanged ...

    try {
      final intentCategory = _classifyIntent(trimmed);
      final res = await _api.post('/ai/chat', {
        'case_id': caseId,
        'message': trimmed,
        'intent_category': intentCategory,
      });
      // ... rest of method unchanged ...
```

- [ ] **Step 7: Run flutter analyze**

```bash
cd mobile && flutter analyze
```

Expected: 0 errors, 0 warnings.

- [ ] **Step 8: Run flutter test**

```bash
cd mobile && flutter test
```

Expected: All tests pass. The test fixtures using `'schedule_text': 'Every 8 hours'` in `medications_notifier_test.dart` and `today_agenda_test.dart` will need to be updated to use `'frequency': 'BID'` — update any failing fixture JSON maps to use the new key.

- [ ] **Step 9: Commit Task 4**

```bash
cd mobile
git add lib/features/medications/providers/medications_notifier.dart \
        lib/features/today/today_screen.dart \
        lib/features/today/providers/today_agenda_notifier.dart \
        lib/features/assistant/providers/chat_assistant_notifier.dart \
        lib/features/assistant/assistant_screen.dart \
        lib/core/l10n/app_en.arb lib/core/l10n/app_es.arb \
        lib/core/l10n/app_it.arb lib/core/l10n/app_de.arb \
        lib/core/l10n/app_fr.arb lib/core/l10n/app_localizations*.dart
git commit -m "feat: mobile frequency localization + intent_category guardrail tagging"
```

---

### Task 5: Final verification

**Files:** None (verification only)

- [ ] **Step 1: Run full backend test suite**

```bash
cd backend && python3 -m pytest tests -v
```

Expected: All tests pass. Check for:
- `test_times_for_frequency_all_codes` ✅
- `test_create_medication_tid_7days_generates_21_reminders` ✅
- `test_create_medication_prn_generates_zero_reminders` ✅
- `test_create_medication_invalid_frequency_rejected` ✅ (422)
- `test_chat_dose_change_intent_is_blocked` ✅ (Italian text)
- `test_chat_diagnosis_intent_is_blocked` ✅ (Spanish text)
- `test_bedrock_provider_has_no_local_regex_guardrail` ✅

- [ ] **Step 2: Run web build + lint**

```bash
cd web && npm run build && npm run lint
```

Expected: 0 errors.

- [ ] **Step 3: Run mobile analyze + test**

```bash
cd mobile && flutter analyze && flutter test
```

Expected: 0 issues.

- [ ] **Step 4: Final commit + tag**

```bash
git add -A
git commit -m "chore: final verification pass — structured scheduling & i18n guardrails complete"
git tag v2.1.0-scheduling-structured
```
