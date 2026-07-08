from app.routers import users
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.routers import auth
from app.database import get_db
from app.routers import cases
from app.routers import medications
from app.dependencies import get_current_user
from app import models
from app.routers import reminders



app = FastAPI(title="Remote CarePro API")


app.include_router(reminders.router)
app.include_router(medications.router)
app.include_router(cases.router)
app.include_router(users.router)
app.include_router(auth.router)
@app.get("/")
def root():
    return {
        "status": "ok",
        "message": "Remote CarePro API is running"
    }


@app.get("/health/db")
def health_db(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {
            "database": "connected"
        }
    except Exception as e:
        return {
            "database": "error",
            "detail": str(e)
        }





@app.get("/me")
def read_current_user(
    current_user: models.User = Depends(get_current_user)
):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role.value
    }
