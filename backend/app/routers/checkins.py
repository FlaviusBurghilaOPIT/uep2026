from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app import models
from app.dependencies import get_current_user


router = APIRouter(
    prefix="/symptoms",
    tags=["symptoms"]
)


@router.post("/checkin")
def create_checkin(
    case_id: str,
    feeling: models.CheckInFeeling,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    case = db.query(models.Case).filter(
        models.Case.id == case_id
    ).first()

    if not case:
        raise HTTPException(
            status_code=404,
            detail="Case not found"
        )

    checkin = models.CheckIn(
        case_id=case_id,
        feeling=feeling
    )

    db.add(checkin)
    db.commit()
    db.refresh(checkin)

    return checkin



@router.get("/patients/{patient_id}/symptoms")
def get_patient_checkins(
    patient_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    checkins = (
        db.query(models.CheckIn)
        .join(models.Case)
        .filter(
            models.Case.patient_id == patient_id
        )
        .all()
    )

    return checkins
