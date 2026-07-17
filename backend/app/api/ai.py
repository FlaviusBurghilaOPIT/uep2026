from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from ..services.rag import generate_recommendation
from ..core.database import get_db

router = APIRouter()

class ChatRequest(BaseModel):
    case_id: str
    message: str
    surgery_type: str | None = None

class ChatResponse(BaseModel):
    reply: str
    sources: list[str]
    out_of_scope: bool

@router.post("/ai/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, db: Session = Depends(get_db)):
    result = generate_recommendation(
        db=db,
        doctor_message=request.message,
        surgery_type=request.surgery_type
    )
    return result