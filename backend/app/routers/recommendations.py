from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user

router = APIRouter(
    prefix="/cases",
    tags=["recommendations"],
)


@router.post("/{case_id}/recommendations", response_model=schemas.RecommendationResponse)
def create_recommendation(
    case_id: str,
    req: schemas.RecommendationCreate,
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

    text_to_save = req.text or req.content or ""
    recommendation = models.Recommendation(case_id=case_id, text=text_to_save)

    db.add(recommendation)
    db.commit()
    db.refresh(recommendation)
    recommendation.content = recommendation.text

    return recommendation


@router.get("/{case_id}/recommendations", response_model=list[schemas.RecommendationResponse])
def get_recommendations(
    case_id: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    # Authorization: the patient who owns the case or the clinician who owns
    # the case may read its recommendations; anyone else gets 404 (same
    # convention as create_recommendation above).
    case = db.query(models.Case).filter(models.Case.id == case_id).first()

    if not case or (
        case.patient_id != current_user.id and case.clinician_id != current_user.id
    ):
        raise HTTPException(status_code=404, detail="Case not found")

    recommendations = (
        db.query(models.Recommendation).filter(models.Recommendation.case_id == case_id).all()
    )

    for r in recommendations:
        r.content = r.text

    return recommendations

