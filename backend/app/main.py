from app.routers import users
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.database import get_db


app = FastAPI(title="Remote CarePro API")
app.include_router(users.router)

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
