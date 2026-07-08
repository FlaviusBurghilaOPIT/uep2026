from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app import models, schemas
from app.dependencies import get_current_user


router = APIRouter(
    prefix="/cases",
    tags=["cases"]
)


@router.post("/")
def create_case(
    case: schemas.CaseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    new_case = models.Case(
        clinician_id=current_user.id,
        patient_id=case.patient_id,
        surgery_type=case.surgery_type
    )

    db.add(new_case)
    db.commit()
    db.refresh(new_case)

    return new_case
