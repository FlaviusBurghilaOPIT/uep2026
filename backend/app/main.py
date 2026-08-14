from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import init_db
from app.routers.ai import router as ai_router
from app.routers.fda import router as fda_router
from app.routers.auth import router as auth_router
from app.routers.cases import router as cases_router
from app.routers.patients import router as patients_router
from app.routers.medications import router as medications_router
from app.routers.reminders import router as reminders_router
from app.routers.checkins import router as checkins_router
from app.routers.adherence import router as adherence_router
from app.routers.recommendations import router as recommendations_router
from app.routers.users import router as users_router
from app.routers.wiki import router as wiki_router

app = FastAPI(
    title="Remote CarePro API",
    version="1.0.0"
)

# Allow React app to call the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
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

@app.get("/")
def root():
    return {"status": "ok", "service": "Remote CarePro API"}

@app.get("/health/db")
def health_db():
    return {"database": "connected"}
# Routes
app.include_router(ai_router)
app.include_router(fda_router)
app.include_router(auth_router)
app.include_router(cases_router)
app.include_router(patients_router)
app.include_router(medications_router)
app.include_router(reminders_router)
app.include_router(checkins_router)
app.include_router(adherence_router)
app.include_router(recommendations_router)
app.include_router(users_router)
app.include_router(wiki_router)
