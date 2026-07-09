from fastapi import APIRouter, Depends

from app.dependencies import get_current_user
from app import models


router = APIRouter(
    prefix="/fda",
    tags=["fda"]
)


@router.get("/drug/{name}")
def get_drug_info(
    name: str,
    current_user: models.User = Depends(get_current_user)
):

    return {
        "drug": name,
        "warning": "FDA safety information will be added here."
    }
