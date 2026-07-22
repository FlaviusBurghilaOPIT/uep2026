Core requirements of Remote CarePro

Clinician web dashboard (React) — the doctor creates a patient case post-surgery and prescribes the medications (name, dose, schedule, duration) as part of the treatment plan. This is the source of truth and your main differentiator vs. a generic reminder app.
Patient companion app (Flutter mobile) — login, and the patient sees their prescribed regimen automatically (no manual drug entry). Plus a simple symptom check-in (e.g. "how do you feel today?" with 3-4 options). Keep it minimal but polished.
Medication reminders + adherence logging — reminders auto-generated from the clinician's prescription; the patient marks each dose taken/missed/skipped. Adherence is the core value proposition, so this must be rock-solid.
Adherence visible on the clinician dashboard — the doctor sees medication status and recovery progress per patient. This closes the loop and is what makes the platform clinical, not consumer.
AWS-backed backend (Python (FastAPI) on AWS) — real deployment using concrete AWS services (EC2/ECS, RDS, S3, Cognito for auth). For an Amazon contest this is non-negotiable — you want to say "it runs on AWS" with proof.
AI chatbot with Amazon Bedrock — answers patient questions about medications and recovery, with guardrails keeping output strictly informational, never diagnostic. The feature that impresses Amazon judges because it uses Bedrock, their flagship service.
What matters for winning (beyond features)
Use as many AWS services as sensibly possible — Bedrock, Cognito, S3, RDS, Lambda. Judges in an AWS contest weigh ecosystem integration heavily; probably the single biggest factor.
A working end-to-end demo — one complete flow beats ten disconnected features: doctor creates case + prescribes → patient sees regimen + gets reminder → logs a dose → asks the chatbot → doctor sees adherence.
FDA safety integration as your differentiator — even a simple version (plain-language summaries of FDA updates for the patient's prescribed medications) makes you memorable and original.
Visible guardrails and safety — in healthcare, showing "never diagnostic, always informational" plus the clinician-authored data model (patient can't self-prescribe) demonstrates maturity and compliance awareness.
Optional (if time allows — don't start here)
Patient-added OTC / pre-existing meds — patients add over-the-counter or prior medications (read-only for prescriptions) so the chatbot and FDA checks see the full picture. Prescribed meds stay clinician-locked.
Automated FDA safety updates — periodic pull of FDA data with generated summaries for the patient's specific medications. Nice but complex; doable as a reduced version.
Document management — clinician uploads prescriptions, discharge letters, clinical notes.
One-page visit summary export — PDF export of the summary to bring to the appointment.
Clinical Practice Guidelines (CPGs) — integration of clinical guidelines; ambitious, save for last.
Symptom trends over time — charts of symptom and recovery progress on the clinician dashboard.

Stack


Frontend (Flutter / Dart)
Flutter SDK — patient mobile app + clinician web dashboard
Dio (or http) — HTTP client for the API
Riverpod — state management
go_router — navigation
json_serializable + build_runner — model serialization
flutter_local_notifications — medication reminders
flutter_secure_storage — token storage
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
Backend
Python 3.12+ virtualenv (or venv/poetry)
PostgreSQL in Docker — local DB
docker-compose — spins up DB + backend together
Uvicorn with --reload — hot reload
.env file — local config (DB url, AWS keys, Cognito ids)
boto3 pointing to real AWS for Bedrock/S3/Cognito (these have no good local emulator — use a dev AWS account)
Frontend
Flutter SDK installed locally
Android emulator / iOS simulator — patient app
Chrome — clinician web dashboard (flutter run -d chrome)
Backend base URL pointed to localhost


Production Deployment
Backend
Docker image pushed to Amazon ECR
Amazon ECS Fargate — runs the containerized FastAPI backend (simplest for a small team)
Amazon RDS (PostgreSQL) — managed database
Amazon Cognito — auth
Amazon S3 — documents
Amazon Bedrock — AI
AWS IAM roles — service permissions
HTTPS via the AWS load balancer
Frontend
Patient app — built APK/IPA for demo (or TestFlight / internal testing)
Clinician dashboard — Flutter web build hosted on S3 + CloudFront (or Amplify Hosting)
Desired
Frontend
freezed — immutable models (nicer DX)
fl_chart — symptom/adherence trend charts
Backend
httpx — async client for openFDA calls
APScheduler — scheduled jobs (FDA pull, reminders)
pytest + pytest-asyncio — automated tests
AWS / infra
Amazon Bedrock Guardrails — informational-only / non-diagnostic enforcement (high value for a healthcare pitch)
openFDA API integration — your differentiator
AWS Lambda — serverless scheduled jobs
Amazon CloudWatch — logs + monitoring
Amazon SNS / Pinpoint — push notifications
Terraform or AWS CDK — Infrastructure as Code (impresses judges)
GitHub Actions — CI/CD
ruff + mypy — linting / type checking
Redis — caching

Project Structure

clinical-platform/
├── README.md
├── docker-compose.yml          # dev locale: db + backend
├── .github/
│   └── workflows/              # CI/CD
│
├── backend/                    # FastAPI (Python)
│   ├── app/
│   │   ├── main.py             # entrypoint FastAPI
│   │   ├── core/               # config, security, settings
│   │   ├── modules/
│   │   │   ├── patients/       # router + service + schemas + models
│   │   │   ├── clinicians/
│   │   │   ├── medications/
│   │   │   ├── adherence/
│   │   │   ├── fda/           
│   │   │   ├── documents/      # S3
│   │   │   └── ai/            # Bedrock + guardrail/PEP
│   │   ├── db/                 # SQLAlchemy session, base
│   │   └── shared/             # utility
│   ├── alembic/                # migration
│   ├── tests/
│   ├── requirements.txt        # (o pyproject.toml)
│   └── Dockerfile
│
├── frontend/
│   ├── patient_app/            # Flutter mobile
│   ├── clinician_dashboard/    # Flutter web (clinic)
│   └── shared/                 # dart shared
│
├── infra/                      # Infrastructure as Code
│   └── ...                     # Terraform o AWS CDK
│
└── docs/
   ├── architecture.md
   └── api.md


Usage requirements 
Patient accounts: who creates them?
Does the clinician create the patient account and the patient receives an invite link? Or does the patient self-register and then get linked to a clinician? Or does an admin create both? 
The patient-clinician relationship: how is it established?
Does the clinician search for a patient by name or ID and link them? Does the patient enter a clinic code? Is it done by a hospital admin system? 
Medication data: How is it imputed 
Does the clinician type the drug name as free text, or do they search from a standardized drug database? A drug database lookup (like RxNorm, which is free and from the US National Library of Medicine) could be used.
FDA data: when and how does it get fetched?
Options are: fetch when the clinician prescribes a drug, fetch on a nightly schedule for all active medications, fetch on demand when the patient opens the medication detail screen, or some combination. Each has different implications for freshness, cost, and complexity.
Recommendation data: where does it come from?
Where do we get the post surgery reccomendations from?
Push notification tokens: how do they get stored?
The Flutter app needs to request notification permission, get the token, and send it to your backend to store.
Chatbot conversation history: is it per session or persistent?
The document doesn't say whether chat history persists across app sessions. Does the patient open the chatbot and see their previous conversations, or does each time they open it start fresh? 

Mentorship week 2 
High Level Description of the Solution
A two-sided platform: one interface for clinicians, one for patients
The clinician is the source of truth, they create the case, prescribe medications, write recovery recommendations
The patient receives everything automatically, no manual entry, no configuration
The AI chatbot (Bedrock) gives patients 24/7 answers within the boundaries of what their clinician prescribed
The FDA integration surfaces drug safety information automatically for whatever the patient has been prescribed
The adherence loop closes back to the clinician dashboard in real time
Core Features 
Clinician-Authored Treatment Plan. The clinician creates a post-surgery case and prescribes medications and recovery recommendations directly from the web dashboard. This data becomes the patient's source of truth, they cannot modify prescribed medications. 
Medication Adherence Tracking. Reminders are auto-generated from the prescription schedule. The patient logs each dose as taken, missed, or skipped. The clinician sees real-time adherence rates, missed dose patterns, and recovery progress on their dashboard. The feedback loop is closed.
AI Recovery Assistant with Guardrails. Powered by Amazon Bedrock, the chatbot answers patient questions about their specific medications and recovery recommendations. It is context-aware (knows what the patient is prescribed) and bounded (never diagnostic, never recommends changing a dose). Amazon Bedrock Guardrails enforce this technically, not just by instruction.
FDA Safety Integration. Using the openFDA API, the platform automatically surfaces safety information, warnings, and recalls for each prescribed medication. Plain-language summaries are generated via Bedrock. Patients see safety information relevant to their specific regimen without searching for it themselves.
Post-Surgery Recovery Recommendations. Beyond medications, clinicians document activity restrictions, wound care instructions, physiotherapy targets, and warning signs as structured records. Patients see these in the app. Progress is logged. The clinician sees recovery status holistically, not just medication adherence.
Low-Level System Design
API Endpoint List 
Auth: handled by Cognito, but document the token flow
Patients: POST /patients, GET /patients/{id}, GET /patients/{id}/case
Cases: POST /cases, GET /cases/{id}
Medications: POST /cases/{id}/medications, GET /cases/{id}/medications
Adherence: POST /adherence/log, GET /patients/{id}/adherence
Recommendations: POST /cases/{id}/recommendations, GET /cases/{id}/recommendations
Symptoms: POST /symptoms/checkin, GET /patients/{id}/symptoms
AI: POST /ai/chat
FDA: GET /fda/drug/{name}
Documents: POST /documents/upload, GET /cases/{id}/documents
Data Flow Narrative 
Clinician logs in via Cognito, JWT stored
Clinician creates patient case in dashboard, POST to /cases
Clinician prescribes medications, POST to /cases/{id}/medications
Backend generates reminder schedule, stores in scheduled reminders table
Patient logs in, GET their case and medications automatically
Flutter app reads medication schedule, schedules local notifications via flutter_local_notifications
Patient receives reminder, opens app, taps "taken", POST to /adherence/log
Clinician dashboard fetches adherence data, displays rates and trends
Patient opens chatbot, asks question, POST to /ai/chat
Backend builds context-aware prompt, calls Bedrock, saves conversation, returns reply
FDA data fetched for prescribed medications, plain-language summary displayed to patient
Where Data Comes From: who creates patient accounts (clinician invites via Cognito), how drug names are handled (free text for MVP, RxNorm lookup as enhancement), when FDA data is fetched (on prescription creation + nightly refresh via Lambda).

