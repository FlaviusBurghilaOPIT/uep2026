from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models
from app.dependencies import get_current_user, get_db_for_user

router = APIRouter(
    prefix="/cases",
    tags=["recommendations"],
)


@router.post("/{case_id}/recommendations")
def create_recommendation(
    case_id: str,
    text: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    case = (
        db.query(models.Case)
        .filter(models.Case.id == case_id, models.Case.clinician_id == current_user.id)
        .first()
    )

    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    recommendation = models.Recommendation(case_id=case_id, text=text)

    db.add(recommendation)
    db.commit()
    db.refresh(recommendation)

    return recommendation


@router.get("/{case_id}/recommendations")
def get_recommendations(
    case_id: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    recommendations = (
        db.query(models.Recommendation).filter(models.Recommendation.case_id == case_id).all()
    )

    return recommendations
