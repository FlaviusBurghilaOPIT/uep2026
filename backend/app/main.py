from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from app import models, schemas
from app.core.database import init_db
from app.database import get_db
from app.dependencies import get_current_user
from app.observability import setup_tracing
from app.routers import (
    adherence,
    agenda,
    ai,
    analytics,
    auth,
    cases,
    checkins,
    fda,
    medications,
    notifications,
    patients,
    recommendations,
    reminders,
    users,
    wiki,
)

app = FastAPI(title="Remote CarePro API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup():
    try:
        setup_tracing()
    except Exception as e:
        print(f"Warning: setup_tracing failed: {e}")
    try:
        init_db()
    except Exception as e:
        print(f"Warning: init_db failed: {e}")


@app.get("/")
def read_root():
    return {"status": "ok"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/health/db")
def health_db(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"database": "connected"}
    except Exception:
        raise HTTPException(status_code=503, detail="Database unavailable")


@app.get("/me", response_model=schemas.UserResponse)
def get_me_root(current_user: models.User = Depends(get_current_user)):
    return current_user


app.include_router(auth.router)
app.include_router(agenda.router)
app.include_router(patients.router)
app.include_router(cases.router)
app.include_router(medications.router)
app.include_router(checkins.router)
app.include_router(adherence.router)
app.include_router(analytics.router)
app.include_router(recommendations.router)
app.include_router(reminders.router)
app.include_router(fda.router)
app.include_router(ai.router)
app.include_router(users.router)
app.include_router(wiki.router)
app.include_router(notifications.router)