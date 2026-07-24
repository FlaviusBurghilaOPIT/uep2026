# Task 2 Report: Integrate Streaming Generator into `/ai/chat` Endpoint

## What was implemented
- Added a new streaming endpoint `@router.post("/chat/stream")` to `backend/app/routers/ai.py`
- Imported `StreamingResponse` from FastAPI and `generate_recommendation_stream` from the RAG service.
- Implemented the logic to check the guardrail, return a mock stream for blocked intents, and otherwise return a `StreamingResponse` wrapping `generate_recommendation_stream`.
- Added the `test_chat_streaming` test to `backend/tests/test_ai_router.py`. Modified the mock slightly to use `monkeypatch` instead of `mocker` since the rest of the file uses `monkeypatch`.

## Test Results

- Run: `pytest tests/test_ai_router.py::test_chat_streaming -v`
- Run: `pytest tests -v`
- Result: 78 passed, 1 skipped

## TDD Evidence

**RED:**
```bash
pytest tests/test_ai_router.py::test_chat_streaming -v
```
```text
tests/test_ai_router.py::test_chat_streaming FAILED                      [100%]

=================================== FAILURES ===================================
_____________________________ test_chat_streaming ______________________________

obj = <module 'app.routers.ai' from '/Users/flavius/OPIT/uep2026/backend/app/routers/ai.py'>
name = 'generate_recommendation_stream', ann = 'app.routers.ai'

    def annotated_getattr(obj: object, name: str, ann: str) -> object:
        try:
>           obj = getattr(obj, name)
                  ^^^^^^^^^^^^^^^^^^
E           AttributeError: module 'app.routers.ai' has no attribute 'generate_recommendation_stream'
```
*Why the failure was expected:* The endpoint `/ai/chat/stream` did not exist, and `generate_recommendation_stream` was not imported into `app.routers.ai`.

**GREEN:**
```bash
pytest tests/test_ai_router.py::test_chat_streaming -v
```
```text
tests/test_ai_router.py::test_chat_streaming PASSED                      [100%]
```

## Files changed
- `backend/app/routers/ai.py`
- `backend/tests/test_ai_router.py`

## Self-review findings
- Completeness: All requirements were fully implemented. The test covers the streaming behavior.
- Quality: Used `monkeypatch` instead of `mocker` because it is the built-in standard pytest fixture that this project already uses. The code matches the provided specification exactly.
- Testing: The tests pass cleanly. The full test suite was run and 78/78 tests pass (1 skipped).

## Issues or concerns
- None. Everything went smoothly.

## Fixes Applied
- Extracted shared logic into `_process_chat_request` helper function to keep the router DRY.
- Updated `/chat/stream` to persist both user and assistant messages, similar to the regular `/chat` endpoint. Assistant messages are accumulated as the stream is generated and then persisted at the end.
- Changed unused `current_user` dependency to `_`.
- Added edge case test coverage in `test_ai_router.py` for 404 (case not found) and guardrail block (`in_scope=False`).

**Test Output:**
```bash
pytest backend/tests/test_ai_router.py -v
```
```text
============================= test session starts ==============================
platform darwin -- Python 3.11.11, pytest-9.0.3, pluggy-1.6.0 -- /Users/flavius/.pyenv/versions/3.11.11/bin/python3.11
cachedir: .pytest_cache
rootdir: /Users/flavius/OPIT/uep2026/backend
configfile: pyproject.toml
plugins: anyio-4.12.1, langsmith-0.7.1, cov-7.1.0
collecting ... collected 8 items

backend/tests/test_ai_router.py::test_chat_general_question_is_in_scope PASSED [ 12%]
backend/tests/test_ai_router.py::test_chat_dose_change_intent_is_blocked PASSED [ 25%]
backend/tests/test_ai_router.py::test_chat_diagnosis_intent_is_blocked PASSED [ 37%]
backend/tests/test_ai_router.py::test_chat_default_intent_is_general_question PASSED [ 50%]
backend/tests/test_ai_router.py::test_chat_persists_both_turns PASSED    [ 62%]
backend/tests/test_ai_router.py::test_chat_streaming PASSED              [ 75%]
backend/tests/test_ai_router.py::test_chat_stream_case_not_found PASSED  [ 87%]
backend/tests/test_ai_router.py::test_chat_stream_guardrail_failure PASSED [100%]

======================== 8 passed, 20 warnings in 3.90s ========================
```
