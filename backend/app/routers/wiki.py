import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user, require_clinician

router = APIRouter(prefix="/wiki", tags=["wiki"])


@router.post("/generate", response_model=schemas.WikiArticleResponse)
def generate_article(
    surgery_type: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_clinician),
):
    cases = db.query(models.Case).filter(models.Case.surgery_type == surgery_type).all()

    lines = [f"# Recovery notes for {surgery_type}\n"]
    case_ids = []
    for case in cases:
        recs = (
            db.query(models.Recommendation).filter(models.Recommendation.case_id == case.id).all()
        )
        for rec in recs:
            lines.append(f"- {rec.text}")
        if recs:
            case_ids.append(case.id)

    article = models.WikiArticle(
        surgery_type=surgery_type,
        content_md="\n".join(lines),
        source_case_ids=json.dumps(case_ids),
    )
    db.add(article)
    db.commit()
    db.refresh(article)

    return article


@router.get("/", response_model=list[schemas.WikiArticleResponse])
def list_articles(
    db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)
):
    return db.query(models.WikiArticle).all()


@router.get("/{article_id}", response_model=schemas.WikiArticleResponse)
def get_article(
    article_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    article = db.query(models.WikiArticle).filter(models.WikiArticle.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    return article


@router.patch("/{article_id}", response_model=schemas.WikiArticleResponse)
def update_article(
    article_id: str,
    update: schemas.WikiArticleUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_clinician),
):
    article = db.query(models.WikiArticle).filter(models.WikiArticle.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")

    if update.content_md is not None:
        article.content_md = update.content_md
    if update.status is not None:
        article.status = models.WikiArticleStatus(update.status)
        if article.status == models.WikiArticleStatus.approved:
            article.approved_by = current_user.id

    db.commit()
    db.refresh(article)

    return article
