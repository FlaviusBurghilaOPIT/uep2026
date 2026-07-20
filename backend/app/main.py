from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import init_db
from app.api.ai import router as ai_router
from app.api.fda import router as fda_router
from app.routers.auth import router as auth_router

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

# Routes
app.include_router(ai_router) 
app.include_router(fda_router)
app.include_router(auth_router)
app.include_router(fda_router)
