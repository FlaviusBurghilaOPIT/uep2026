from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user, require_clinician
from app.services.sns_push_service import SNSPushService

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/register-token", response_model=schemas.DeviceTokenResponse)
def register_device_token(
    payload: schemas.DeviceTokenRegisterRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Registers or updates a device token for the current user.
    """
    if not payload.token or not payload.token.strip():
        raise HTTPException(status_code=400, detail="Token must not be empty")

    service = SNSPushService(db)
    device_token = service.register_endpoint(
        user_id=current_user.id,
        token=payload.token.strip(),
        platform=payload.platform,
    )
    return device_token


@router.post("/send-test")
def send_test_push_notification(
    payload: schemas.SendTestPushRequest,
    current_user: models.User = Depends(require_clinician),
    db: Session = Depends(get_db),
):
    """
    Sends a test remote push notification to a target user. Restricted to clinicians/admin.
    """
    target_user = db.query(models.User).filter(models.User.id == payload.user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user not found")

    service = SNSPushService(db)
    result = service.send_push_notification(
        user_id=payload.user_id,
        title=payload.title,
        body=payload.body,
        data_payload=payload.data_payload,
    )
    return result
