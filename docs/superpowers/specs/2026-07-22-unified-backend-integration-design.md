# Unified Python Backend Integration & Patient Invite Flow Specification

**Date**: 2026-07-22  
**Status**: Approved  
**Author**: Remote CarePro Team  

---

## 1. Overview & Objective

The Remote CarePro platform is a two-sided post-surgery care application comprising a Clinician Web Dashboard (React/Vite) and a Patient Mobile Companion App (Flutter/Dart). 

This design unifies all communication across the Clinician Web Dashboard and Patient Mobile Companion App to consume directly and exclusively the single source of truth: the Python FastAPI Backend (`http://localhost:8000`). It replaces all legacy hardcoded mock server calls (`http://localhost:8001`) on the web dashboard and dummy `Future.delayed` hardcoded state in the Flutter mobile application. Furthermore, it introduces a secure **Clinician Invite & Patient Onboarding Flow** with pre-filled mandatory clinical data.

---

## 2. Architecture & System Scope

```
┌───────────────────────────────┐                  ┌───────────────────────────────┐
│  Clinician Web Dashboard      │                  │  Patient Mobile Companion     │
│  (React / Vite - Port 5173)   │                  │  (Flutter / Dart)             │
└──────────────┬────────────────┘                  └──────────────┬────────────────┘
               │                                                  │
               │ HTTP / REST (JWT Bearer Auth)                    │ HTTP / REST (JWT Bearer Auth)
               ▼                                                  ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           Python FastAPI Backend                                 │
│                           (Port 8000 - Single Source of Truth)                   │
├──────────────────────────────────────────────────────────────────────────────────┤
│ Mounted Routers:                                                                 │
│  - /auth           - /patients          - /cases              - /medications     │
│  - /checkins       - /adherence         - /recommendations    - /reminders       │
│  - /fda            - /ai                - /users              - /wiki            │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │
                                         ▼
                             ┌──────────────────────┐
                             │ PostgreSQL / SQLite  │
                             │ Database & Bedrock   │
                             └──────────────────────┘
```

---

## 3. Detailed Component Specifications

### 3.1 Backend Service Consolidation (`backend/app`)

1. **Router Mounting (`backend/app/main.py`)**:
   - Mount all 12 feature routers in `main.py`:
     - `app.include_router(auth.router)`
     - `app.include_router(patients.router)`
     - `app.include_router(cases.router)`
     - `app.include_router(medications.router)`
     - `app.include_router(checkins.router)`
     - `app.include_router(adherence.router)`
     - `app.include_router(recommendations.router)`
     - `app.include_router(reminders.router)`
     - `app.include_router(fda.router)`
     - `app.include_router(ai.router)`
     - `app.include_router(users.router)`
     - `app.include_router(wiki.router)`
   - Configure CORS middleware allowing requests from `http://localhost:5173` (React web), mobile emulators/devices (`http://10.0.2.2:8000` / `*`), and custom origins.

2. **Patient Invitation & Onboarding Protocol**:
   - **Endpoint `POST /patients/invite`**:
     - **Request**: `{ "email": "...", "full_name": "...", "surgery_type": "...", "emergency_contact_phone": "..." }`
     - **Behavior**: Creates a `User` (role `patient`, status `pending_onboarding`), generates a 6-digit `invite_code`, and provisions an initial `Case` linked to the inviting clinician.
     - **Response**: `{ "patient_id": "...", "case_id": "...", "invite_code": "123456", "message": "Patient invited successfully" }`
   - **Endpoint `POST /auth/verify-invite`**:
     - **Request**: `{ "email": "...", "invite_code": "123456" }`
     - **Behavior**: Validates invite code and returns pre-populated mandatory profile details (`full_name`, `email`, `surgery_type`, `clinician_name`).
   - **Endpoint `POST /auth/complete-onboarding`**:
     - **Request**: `{ "email": "...", "invite_code": "123456", "password": "...", "date_of_birth": "...", "phone": "..." }`
     - **Behavior**: Sets user password, completes optional profile info, transitions status to `active`, and returns JWT `access_token`.

3. **Database Seeding (`backend/app/scripts/seed_data.py`)**:
   - Seed default clinician (`clinician@example.com` / `password123`) and patient (`patient@example.com` / `password123`) along with cases, medications, recommendations, and sample check-ins for instant out-of-the-box testing.

---

### 3.2 Clinician Web Dashboard Integration (`web/`)

1. **Centralized API Client (`web/src/api/client.ts` / `web/src/config.ts`)**:
   - Base URL driven by `import.meta.env.VITE_API_URL || 'http://localhost:8000'`.
   - Automatic `Authorization: Bearer <token>` header injection and global error handling.

2. **Page Refactoring**:
   - **`LoginPage.tsx`**: Authenticates against `POST /auth/login`, stores JWT token in `localStorage`, and sets current clinician context.
   - **`PatientsPage.tsx`**: Queries `GET /cases` and `GET /patients/{id}` for live patient lists and adherence summary metrics.
   - **`CreatePatientPage.tsx` / `CreateCasePage.tsx`**: Submits patient invitation payload to `POST /patients/invite` and displays the generated 6-digit invitation code.
   - **`MedicationsPage.tsx` & `MedicationsListPage.tsx`**: Performs CRUD operations via `POST /cases/{id}/medications` and `GET /cases/{id}/medications`.
   - **`RecommendationsPage.tsx`**: Authors care instructions via `POST /cases/{id}/recommendations`.
   - **`FDAPage.tsx`**: Fetches drug safety data via `GET /fda/drug/{name}`.

---

### 3.3 Patient Mobile Companion Integration (`mobile/`)

1. **API Service Layer (`mobile/lib/core/services/api_service.dart`)**:
   - Dynamic base URL: `http://10.0.2.2:8000` (Android emulator) / `http://localhost:8000` (iOS / Web / Desktop).
   - Manages token persistence via `flutter_secure_storage` or `shared_preferences`.

2. **Provider & UI Refactoring**:
   - **`AuthProvider`**:
     - `verifyInvite(email, code)`: Invokes `POST /auth/verify-invite` to load mandatory pre-filled profile details.
     - `completeOnboarding(...)`: Invokes `POST /auth/complete-onboarding` to register password, DOB, phone, and obtain JWT token.
     - `signIn(email, password)`: Invokes `POST /auth/login`.
   - **`PatientCaseProvider` / `MedicationProvider`**:
     - Fetches active treatment plan via `GET /patients/me/case` and `GET /cases/{id}/medications`.
   - **`CheckinProvider` / `AdherenceProvider`**:
     - Sends dose logs (`taken`, `missed`, `skipped`) to `POST /adherence/log`.
     - Sends symptom check-ins to `POST /checkins`.
   - **`AssistantProvider`**:
     - Posts chat inquiries to `POST /ai/chat` on the backend.

---

## 4. Error Handling & Guardrails

1. **Authentication Errors**: Invalid login credentials or expired tokens trigger HTTP `401 Unauthorized`. Clients automatically clear tokens and redirect to login/onboarding screens.
2. **Clinical Guardrails**: All AI queries issued by patients are processed by the Python backend's Bedrock provider, enforcing informational-only responses without diagnostic or prescription alterations.
3. **FDA Fallback**: If openFDA service is unreachable, backend returns locally cached safety information.

---

## 5. Verification Plan

1. **Backend Tests**: Run `pytest backend/tests` to confirm router mounting, JWT issuance, invite verification, and case management.
2. **Web Build & Lint**: Run `npm run build` and `npm run lint` in `web/` to confirm zero missing types or leftover mock `8001` endpoints.
3. **Mobile Analysis**: Run `flutter analyze` in `mobile/` to confirm static safety and zero remaining hardcoded mock state.
