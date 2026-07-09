from fastapi import APIRouter, Depends
from app import schemas, models
from app.dependencies import get_current_user


router = APIRouter(
    prefix="/ai",
    tags=["ai"]
)


@router.post("/chat", response_model=schemas.ChatResponse)
def chat(
    request: schemas.ChatRequest,
    current_user: models.User = Depends(get_current_user)
):

    return {
        "reply": "I can help you with your recovery questions."
    }
