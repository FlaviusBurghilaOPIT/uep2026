from fastapi import Depends, FastAPI
from sqlalchemy import text
from sqlalchemy.orm import Session

from app import models
from app.database import get_db
from app.dependencies import get_current_user
from app.routers import (
    adherence,
    ai,
    auth,
    cases,
    checkins,
    fda,
    patients,
    recommendations,
    reminders,
    users,
    wiki,
)

app = FastAPI(
    title="Remote CarePro API",
    description=(
        "Backend for Remote CarePro: clinician-authored post-surgery cases, "
        "medication adherence tracking, an AI recovery assistant with guardrails, "
        "and openFDA safety integration."
    ),
    version="0.2.0",
    openapi_tags=[
        {
            "name": "auth",
            "description": "Local email/password login (see AuthProvider factory for Cognito).",
        },
        {
            "name": "cases",
            "description": (
                "Manages clinician-authored post-surgery cases and patient case retrieval."
            ),
        },
        {
            "name": "patients",
            "description": "Manages patient user creation and retrieval.",
        },
        {
            "name": "medications",
            "description": "Manages prescribed medications for patient cases.",
        },
        {
            "name": "adherence",
            "description": (
                "Tracks patient medication adherence through dose logging and adherence metrics."
            ),
        },
        {
            "name": "reminders",
            "description": (
                "Creates, lists, and updates the status of scheduled medication reminders "
                "for patient adherence."
            ),
        },
        {
            "name": "recommendations",
            "description": (
                "Manages clinician recommendations and guidance for patient recovery cases."
            ),
        },
        {
            "name": "symptoms",
            "description": "Tracks patient symptom check-ins and recovery progress reports.",
        },
        {
            "name": "ai",
            "description": (
                "AI-powered recovery assistant providing guardrailed patient support "
                "and guidance."
            ),
        },
        {
            "name": "fda",
            "description": (
                "Provides openFDA drug safety lookup for medications (live implementation pending)."
            ),
        },
        {
            "name": "users",
            "description": "Creates clinician users and manages user accounts.",
        },
    ],
)

app.include_router(fda.router)
app.include_router(ai.router)
app.include_router(checkins.router)
app.include_router(recommendations.router)
app.include_router(adherence.router)
app.include_router(reminders.router)
app.include_router(cases.router)
app.include_router(patients.router)
app.include_router(users.router)
app.include_router(auth.router)
app.include_router(wiki.router)


@app.get("/")
def root():
    return {"status": "ok", "message": "Remote CarePro API is running"}


@app.get("/health/db")
def health_db(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"database": "connected"}
    except Exception as e:
        return {"database": "error", "detail": str(e)}


@app.get("/me")
def read_current_user(current_user: models.User = Depends(get_current_user)):
    return {"id": current_user.id, "email": current_user.email, "role": current_user.role.value}
