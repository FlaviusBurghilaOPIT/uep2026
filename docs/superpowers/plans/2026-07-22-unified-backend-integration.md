# Unified Python Backend Integration & Patient Invite Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the Clinician Web Dashboard and Patient Mobile Companion App to consume directly and exclusively the single source of truth—the Python FastAPI backend (`http://localhost:8000`)—and implement the clinician patient invite & onboarding workflow.

**Architecture:** The Python backend (`backend/app/main.py`) mounts all 12 REST API feature routers and provides FastAPI JWT authentication along with clinician invite/onboarding endpoints. The React web dashboard (`web/`) uses a unified API client pointing to `VITE_API_URL` (`http://localhost:8000`) for all clinician workflows. The Flutter mobile app (`mobile/`) uses a central `ApiService` connecting to `http://localhost:8000` (or `http://10.0.2.2:8000` on Android) for real auth, regimen sync, dose logging, FDA safety, and AI assistant interaction.

**Tech Stack:** Python 3.12, FastAPI, SQLAlchemy 2.x, Pydantic v2, pytest, React 18, Vite, TypeScript, Flutter 3.x, Dart 3.x, Riverpod/Provider, HTTP.

## Global Constraints

- **Python Backend URL**: `http://localhost:8000` (Mobile Android fallback: `http://10.0.2.2:8000`)
- **No Mock Server Dependency**: Zero requests directed to Prism mock server on port 8001.
- **No Hardcoded State**: All dummy delayed mock data in Flutter (`Sarah Mitchell`) replaced with real API calls.
- **JWT Storage**: Web uses `localStorage`; Flutter mobile uses `flutter_secure_storage` or `shared_preferences`.

---

### Task 1: Backend Centralization, Invite Endpoints & Database Seeding

**Files:**
- Modify: `backend/app/main.py`
- Modify: `backend/app/models.py`
- Modify: `backend/app/schemas.py`
- Modify: `backend/app/routers/auth.py`
- Modify: `backend/app/routers/patients.py`
- Create: `backend/app/scripts/seed_data.py`
- Create: `backend/tests/test_main_integration.py`

**Interfaces:**
- Consumes: SQLAlchemy Session, Pydantic schemas.
- Produces: Complete mounted FastAPI application on port 8000 with `/patients/invite`, `/auth/verify-invite`, and `/auth/complete-onboarding`.

- [ ] **Step 1: Write failing tests for backend integration and invite endpoints**

Create `backend/tests/test_main_integration.py`:
```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_patient_invite_and_onboarding_flow():
    # 1. Clinician login
    login_resp = client.post("/auth/login", json={
        "email": "clinician@example.com",
        "password": "password123"
    })
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Clinician invites patient
    invite_resp = client.post("/patients/invite", headers=headers, json={
        "email": "invited_patient@example.com",
        "full_name": "John Doe",
        "surgery_type": "Knee Replacement",
        "emergency_contact_phone": "+123456789"
    })
    assert invite_resp.status_code == 200
    invite_data = invite_resp.json()
    assert "invite_code" in invite_data
    code = invite_data["invite_code"]

    # 3. Patient verifies invite
    verify_resp = client.post("/auth/verify-invite", json={
        "email": "invited_patient@example.com",
        "invite_code": code
    })
    assert verify_resp.status_code == 200
    assert verify_resp.json()["full_name"] == "John Doe"

    # 4. Patient completes onboarding
    complete_resp = client.post("/auth/complete-onboarding", json={
        "email": "invited_patient@example.com",
        "invite_code": code,
        "password": "newpassword123",
        "date_of_birth": "1985-05-15",
        "phone": "+1987654321"
    })
    assert complete_resp.status_code == 200
    assert "access_token" in complete_resp.json()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk pytest backend/tests/test_main_integration.py`
Expected: FAIL due to missing routes or models.

- [ ] **Step 3: Update models, schemas, routers, and main.py**

1. Update `backend/app/models.py` to ensure `User` has `invite_code`, `status` (`pending_onboarding`, `active`), `phone`, `date_of_birth`.
2. Update `backend/app/schemas.py` with `PatientInviteRequest`, `PatientInviteResponse`, `VerifyInviteRequest`, `CompleteOnboardingRequest`.
3. Implement `POST /patients/invite` in `backend/app/routers/patients.py`.
4. Implement `POST /auth/verify-invite` and `POST /auth/complete-onboarding` in `backend/app/routers/auth.py`.
5. Update `backend/app/main.py` to import and mount all 12 routers:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import init_db
from app.routers import (
    auth, patients, cases, medications, checkins,
    adherence, recommendations, reminders, fda, ai, users, wiki
)

app = FastAPI(title="Remote CarePro API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

@app.on_event("startup")
async def startup():
    init_db()

@app.get("/health")
def health():
    return {"status": "ok"}

app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(cases.router)
app.include_router(medications.router)
app.include_router(checkins.router)
app.include_router(adherence.router)
app.include_router(recommendations.router)
app.include_router(reminders.router)
app.include_router(fda.router)
app.include_router(ai.router)
app.include_router(users.router)
app.include_router(wiki.router)
```
6. Create `backend/app/scripts/seed_data.py` to seed default clinician (`clinician@example.com` / `password123`) and patient (`patient@example.com` / `password123`) with initial cases and medications.

- [ ] **Step 4: Run pytest to verify all tests pass**

Run: `rtk pytest backend/tests/test_main_integration.py`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
rtk git add backend/
rtk git commit -m "feat(backend): mount all feature routers, implement patient invite/onboarding endpoints, and add seed data script"
```

---

### Task 2: Clinician Web Dashboard API Consolidation

**Files:**
- Create: `web/src/api/client.ts`
- Modify: `web/src/pages/LoginPage.tsx`
- Modify: `web/src/pages/PatientsPage.tsx`
- Modify: `web/src/pages/CreatePatientPage.tsx`
- Modify: `web/src/pages/CreateCasePage.tsx`
- Modify: `web/src/pages/MedicationsPage.tsx`
- Modify: `web/src/pages/RecommendationsPage.tsx`
- Modify: `web/src/pages/FDAPage.tsx`

**Interfaces:**
- Consumes: FastAPI endpoints on `http://localhost:8000`.
- Produces: Fully functional React web dashboard calling Python backend.

- [ ] **Step 1: Create central API client `web/src/api/client.ts`**

```typescript
const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export async function apiFetch<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({ detail: 'API Error' }));
    throw new Error(errorData.detail || `Request failed with status ${response.status}`);
  }

  return response.json();
}
```

- [ ] **Step 2: Refactor web pages to use `apiFetch` and point to Python backend**

1. `LoginPage.tsx`: Submit credentials to `/auth/login`, save `access_token` to `localStorage.setItem('token', data.access_token)`.
2. `PatientsPage.tsx`: Fetch cases via `apiFetch('/cases')` and `apiFetch('/patients')`.
3. `CreatePatientPage.tsx`: Submit invitation to `/patients/invite`, rendering the returned 6-digit `invite_code` prominently for the clinician.
4. `MedicationsPage.tsx`: Post new medications to `/cases/${caseId}/medications` and fetch list from `/cases/${caseId}/medications`.
5. `RecommendationsPage.tsx`: Post recommendations to `/cases/${caseId}/recommendations`.
6. `FDAPage.tsx`: Query FDA info from `/fda/drug/${name}`.

- [ ] **Step 3: Run web lint and build checks**

Run: `cd web && npm run build`
Expected: Build succeeds with zero errors.

- [ ] **Step 4: Commit changes**

```bash
rtk git add web/
rtk git commit -m "feat(web): point web dashboard directly to python backend on port 8000 via centralized API client"
```

---

### Task 3: Patient Mobile Companion Centralized Network Layer & Real State Integration

**Files:**
- Create: `mobile/lib/core/services/api_service.dart`
- Modify: `mobile/lib/core/providers/auth_provider.dart`
- Modify: `mobile/lib/features/auth/onboarding_screen.dart` / sign in screens
- Modify: `mobile/lib/features/today/today_screen.dart`
- Modify: `mobile/lib/features/checkin/checkin_screen.dart`
- Modify: `mobile/lib/features/assistant/assistant_screen.dart`

**Interfaces:**
- Consumes: FastAPI endpoints on `http://localhost:8000` (or `http://10.0.2.2:8000`).
- Produces: Fully integrated Flutter app communicating with Python backend.

- [ ] **Step 1: Create `ApiService` in `mobile/lib/core/services/api_service.dart`**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<http.Response> get(String path) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
}
```

- [ ] **Step 2: Refactor `AuthProvider` to use real API calls**

Update `mobile/lib/core/providers/auth_provider.dart`:
- Implement `verifyInvite(String email, String inviteCode)` -> calls `ApiService.post('/auth/verify-invite', ...)` and stores returned mandatory profile fields.
- Implement `completeOnboarding({required String email, required String inviteCode, required String password, required String dateOfBirth, required String phone})` -> calls `ApiService.post('/auth/complete-onboarding', ...)`, saves token via `ApiService.setToken()`, and sets `_isSignedIn = true`.
- Implement `signIn({required String email, required String password})` -> calls `ApiService.post('/auth/login', ...)`, saves token, fetches current patient profile via `/me`, and updates auth state.

- [ ] **Step 3: Connect Patient UI Screens to Backend**

- `today_screen.dart`: Fetch active medications and dose logs from `/cases/{id}/medications` and `/adherence/stats`. Tapping dose item posts to `/adherence/log`.
- `checkin_screen.dart`: Submits symptom form to `/checkins`.
- `assistant_screen.dart`: Submits chatbot query to `/ai/chat` and renders response.

- [ ] **Step 4: Run flutter analysis check**

Run: `cd mobile && flutter analyze`
Expected: No breaking structural errors or missing imports.

- [ ] **Step 5: Commit changes**

```bash
rtk git add mobile/
rtk git commit -m "feat(mobile): integrate ApiService and connect AuthProvider, checkin, adherence, and AI assistant to python backend"
```

---

### Task 4: End-to-End Verification & Verification Run

**Files:**
- Execute verification suite across backend, web, and mobile repositories.

- [ ] **Step 1: Run pytest backend test suite**
Run: `rtk pytest backend/tests`
Expected: ALL PASS

- [ ] **Step 2: Run web build check**
Run: `cd web && npm run build`
Expected: PASS

- [ ] **Step 3: Run mobile analyzer check**
Run: `cd mobile && flutter analyze`
Expected: PASS

- [ ] **Step 4: Commit final verification status**
```bash
rtk git commit --allow-empty -m "chore: complete end-to-end integration of single source of truth python backend across web and mobile"
```
