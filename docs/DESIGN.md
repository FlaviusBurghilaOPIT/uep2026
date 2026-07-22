Question
Answer
Problem
After surgery, patients must follow a clinician-prescribed medication regimen and recovery plan, but adherence is the core challenge and clinicians lose visibility once the patient leaves. Generic reminder apps are consumer tools where the patient self-enters data and there is no clinician loop.
Solution & delivery model
A two-sided, cloud-hosted platform delivered as software-as-a-service: a web dashboard for clinicians and a mobile companion app for patients, on an AWS backend. The clinician is the source of truth; the patient receives everything automatically.
Industry / domain
Healthcare (clinical post-surgery follow-up / medication adherence).
Target audience
Clinicians managing post-surgery cases, and their post-surgery patients.
Competitors / positioning
Positioned against generic medication-reminder apps and consumer health apps. The differentiator is being clinical, not consumer: clinician-authored data the patient cannot self-prescribe.
Added value
Clinician-authored treatment plan as the source of truth, a closed adherence loop back to the clinician, an AI assistant with technical guardrails (informational, never diagnostic), and automatic FDA safety information for the patient's specific medications.



2. The Problem
After surgery, a patient must follow the regimen their clinician prescribes — the right medications, at the right dose, on the right schedule, for the right duration — alongside recovery recommendations. Adherence to that regimen is the core problem, and once the patient is discharged the clinician has no visibility into whether doses are being taken, missed, or skipped, or how recovery is progressing.
Generic medication-reminder apps do not solve this for a clinical setting:
They are consumer tools — the patient self-enters their own drugs, so the data is not authoritative and the patient could effectively self-prescribe.
There is no feedback loop to the clinician; the doctor never sees adherence or recovery status.
Patients have no bounded, trustworthy source for questions about their specific medications and recovery, and no automatic surfacing of drug-safety information.
Remote CarePro closes this gap by making the clinician the source of truth, pushing the regimen to the patient automatically, logging every dose, and returning adherence and recovery status to the clinician dashboard in real time — making the platform clinical, not consumer.

3. High-Level Description of the Solution
A two-sided platform: one interface for clinicians, one for patients.
The clinician is the source of truth — they create the case, prescribe medications, and write recovery recommendations.
The patient receives everything automatically — no manual entry, no configuration.
The AI chatbot (Amazon Bedrock) gives patients 24/7 answers within the boundaries of what their clinician prescribed.
The FDA integration surfaces drug-safety information automatically for whatever the patient has been prescribed.
The adherence loop closes back to the clinician dashboard in real time.

4. Core Features

Backend
Frontend -> mobile / web (react)

readme.md 

The platform has five core features
Clinician-Authored Treatment Plan. The clinician creates a post-surgery case and prescribes medications and recovery recommendations directly from the web dashboard. This data becomes the patient's source of truth; the patient cannot modify prescribed medications.


Medication Adherence Tracking. Reminders are auto-generated from the prescription schedule. The patient logs each dose as taken, missed, or skipped. The clinician sees real-time adherence rates, missed-dose patterns, and recovery progress on their dashboard. The feedback loop is closed.


AI Recovery Assistant with Guardrails. Powered by Amazon Bedrock, the chatbot answers patient questions about their specific medications and recovery recommendations. It is context-aware (knows what the patient is prescribed) and bounded (never diagnostic, never recommends changing a dose). Amazon Bedrock Guardrails enforce this technically, not just by instruction.


FDA Safety Integration. Using the openFDA API, the platform automatically surfaces safety information, warnings, and recalls for each prescribed medication. Plain-language summaries are generated via Bedrock. Patients see safety information relevant to their specific regimen without searching for it themselves.


Post-Surgery Recovery Recommendations. Beyond medications, clinicians document activity restrictions, wound-care instructions, physiotherapy targets, and warning signs as structured records. Patients see these in the app and progress is logged, so the clinician sees recovery status holistically, not just medication adherence.



5. Low-Level System Design
5.1 API Endpoint List
Auth — handled by Cognito (token flow documented in §5.2).
Patients — POST /patients, GET /patients/{id}, GET /patients/{id}/case
Cases — POST /cases, GET /cases/{id}
Medications — POST /cases/{id}/medications, GET /cases/{id}/medications
Adherence — POST /adherence/log, GET /patients/{id}/adherence
Recommendations — POST /cases/{id}/recommendations, GET /cases/{id}/recommendations
Symptoms — POST /symptoms/checkin, GET /patients/{id}/symptoms
AI — POST /ai/chat
FDA — GET /fda/drug/{name}
Documents — POST /documents/upload, GET /cases/{id}/documents
5.2 Data Flow Narrative
Clinician logs in via Cognito; JWT stored.
Clinician creates a patient case in the dashboard — POST /cases.
Clinician prescribes medications — POST /cases/{id}/medications.
Backend generates the reminder schedule and stores it in the scheduled-reminders table.
Patient logs in and automatically gets their case and medications — GET their case + medications.
The Flutter app reads the medication schedule and schedules local notifications via flutter_local_notifications.
Patient receives a reminder, opens the app, taps "taken" — POST /adherence/log.
The clinician dashboard fetches adherence data and displays rates and trends.
Patient opens the chatbot and asks a question — POST /ai/chat.
The backend builds a context-aware prompt, calls Bedrock, saves the conversation, and returns the reply.
FDA data is fetched for prescribed medications and a plain-language summary is displayed to the patient.



















5.3 Key User Flow (sequence)











5.4 Data Model (entities)
Entities and relationships derived from the API endpoints, modules, and feature descriptions.












6. Alternatives Considered
Patient accounts — who creates them? Options: the clinician creates the account and the patient receives an invite link; the patient self-registers and is then linked to a clinician; or an admin creates both. Decision: the clinician invites the patient via Cognito.
Patient–clinician relationship — how is it established? Options: the clinician searches for a patient by name or ID and links them; the patient enters a clinic code; or it is done through a hospital admin system. Status: open — not yet resolved.
Medication data — how is it entered? Options: the clinician types the drug name as free text, or searches a standardized drug database (e.g. RxNorm, free, from the US National Library of Medicine). Decision: free text for the MVP, with RxNorm lookup as an enhancement.
FDA data — when and how is it fetched? Options: fetch when the clinician prescribes a drug; fetch nightly for all active medications; fetch on demand when the patient opens the medication-detail screen; or a combination — each with different trade-offs for freshness, cost, and complexity. Decision: fetch on prescription creation, plus a nightly refresh via AWS Lambda.
Recommendation data — where does it come from? Decision: clinician-authored — clinicians document activity restrictions, wound-care instructions, physiotherapy targets, and warning signs directly as structured records. (Integration of Clinical Practice Guidelines is listed as an ambitious, optional extension.)
Push notification tokens — how are they stored? Approach: the Flutter app requests notification permission, obtains the token, and sends it to the backend to be stored. (Local reminders use flutter_local_notifications; SNS / Pinpoint push is a desired extension.)
Chatbot conversation history — per session or persistent? Options: each chat session starts fresh, or the patient sees previous conversations. Status: flagged as open; however, the data-flow narrative specifies that the backend saves the conversation, implying persistence.

7. Technology Stack
Frontend (Flutter / Dart)
Flutter SDK — patient mobile app + clinician web dashboard
Dio (or http) — HTTP client for the API
Riverpod — state management
go_router — navigation
json_serializable + build_runner — model serialization
flutter_local_notifications — medication reminders
flutter_secure_storage — token storage
Note: the core-requirements section describes the clinician dashboard as React, while the stack section lists Flutter (web) for both apps. To be reconciled with the mentor.
Backend (Python / FastAPI)
FastAPI — REST API framework
Pydantic v2 — data validation / schemas
SQLAlchemy 2.x — ORM
Alembic — database migrations
psycopg (or asyncpg) — PostgreSQL driver
boto3 — AWS SDK (Bedrock, S3, Cognito)
python-jose — JWT verification
Uvicorn — ASGI server
Database & AWS
PostgreSQL — relational database
Amazon Cognito — auth + roles (patient / clinician)
Amazon RDS (PostgreSQL) — managed DB in production
Amazon S3 — document storage
Amazon Bedrock — AI chatbot
Docker — backend containerization
Local Development
Backend: Python 3.12+ virtualenv (venv / poetry); PostgreSQL in Docker; docker-compose (DB + backend); Uvicorn with --reload; .env for local config; boto3 pointing to a real dev AWS account for Bedrock/S3/Cognito (no good local emulator).
Frontend: Flutter SDK installed locally; Android emulator / iOS simulator for the patient app; Chrome for the clinician dashboard (flutter run -d chrome); backend base URL pointed to localhost.
Production Deployment
Backend: Docker image pushed to Amazon ECR; runs on Amazon ECS Fargate; Amazon RDS (PostgreSQL); Amazon Cognito; Amazon S3; Amazon Bedrock; AWS IAM roles for permissions; HTTPS via the AWS load balancer.
Frontend: patient app built as APK/IPA for the demo (or TestFlight / internal testing); clinician dashboard as a Flutter web build hosted on S3 + CloudFront (or Amplify Hosting).
Desired (stretch)
Frontend: freezed (immutable models), fl_chart (symptom/adherence trend charts).
Backend: httpx (async openFDA calls), APScheduler (scheduled jobs), pytest + pytest-asyncio (tests).
AWS / infra: Amazon Bedrock Guardrails (informational-only enforcement), openFDA API integration, AWS Lambda (serverless scheduled jobs), Amazon CloudWatch (logs + monitoring), Amazon SNS / Pinpoint (push notifications), Terraform or AWS CDK (IaC), GitHub Actions (CI/CD), ruff + mypy (lint / types), Redis (caching).

8. System Architecture
AWS-backed architecture from the production-deployment plan. Solid boxes are the core deployment; the nightly FDA job via Lambda reflects the decision in §6.

