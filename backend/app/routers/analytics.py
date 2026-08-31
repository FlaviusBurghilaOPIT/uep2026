import json
from statistics import median

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user, require_clinician

router = APIRouter(
    prefix="/analytics",
    tags=["analytics"],
)

# Event taxonomy from docs/product/09-measurement-plan.md §3.1.
# Events outside this list are rejected — the taxonomy is deliberately closed
# so no one can start tracking engagement vanity metrics or PHI by accident.
ALLOWED_EVENTS = {
    "web.auth.login_succeeded",
    "web.patient.invited",
    "web.case.created",
    "web.medication.prescribed",
    "web.recommendation.saved",
    "web.triage.exception_viewed",
    "web.triage.patient_called",
    "web.triage.patient_acknowledged",
}

# Properties may carry IDs, enums, and timestamps only — never free text.
ALLOWED_PROPERTY_KEYS = {"patient_id", "case_id", "severity", "outreach_method"}


@router.post("/events", status_code=201)
def track_event(
    req: schemas.AnalyticsEventIn,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    if req.event_name not in ALLOWED_EVENTS:
        raise HTTPException(status_code=400, detail="Unknown analytics event")

    props = req.properties or {}
    unknown_keys = set(props) - ALLOWED_PROPERTY_KEYS
    if unknown_keys:
        raise HTTPException(
            status_code=400,
            detail=f"Disallowed analytics properties: {sorted(unknown_keys)}",
        )

    event = models.AnalyticsEvent(
        event_name=req.event_name,
        actor_id=current_user.id,
        properties=json.dumps(props) if props else None,
    )
    db.add(event)
    db.commit()
    return {"status": "recorded"}


@router.get("/triage-response", response_model=schemas.TriageResponseStats)
def triage_response_stats(
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):
    """Median time from a Red/Amber exception being viewed on the dashboard
    to the clinician's persisted resolution. Target: < 60 seconds median
    (docs/product/09-measurement-plan.md §2.3)."""

    resolutions = (
        db.query(models.TriageResolution).order_by(models.TriageResolution.resolved_at.asc()).all()
    )

    view_events = (
        db.query(models.AnalyticsEvent)
        .filter(models.AnalyticsEvent.event_name == "web.triage.exception_viewed")
        .all()
    )

    # Latest view timestamp per patient
    last_view: dict[str, list] = {}
    for e in view_events:
        if not e.properties:
            continue
        try:
            patient_id = json.loads(e.properties).get("patient_id")
        except (json.JSONDecodeError, AttributeError):
            continue
        if patient_id:
            last_view.setdefault(patient_id, []).append(e.created_at)

    deltas = []
    for r in resolutions:
        views = [v for v in last_view.get(r.patient_id, []) if v <= r.resolved_at]
        if views:
            deltas.append((r.resolved_at - max(views)).total_seconds())

    return schemas.TriageResponseStats(
        median_seconds=median(deltas) if deltas else None,
        samples=len(deltas),
        resolutions_total=len(resolutions),
    )


@router.get("/triage-acknowledgements", response_model=schemas.TriageAcknowledgementsOut)
def triage_acknowledgements(
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):
    """Latest 'seen' timestamp per patient, so the dashboard can mark an
    exception as looked-at without requiring a full resolution note."""

    events = (
        db.query(models.AnalyticsEvent)
        .filter(models.AnalyticsEvent.event_name == "web.triage.patient_acknowledged")
        .order_by(models.AnalyticsEvent.created_at.asc())
        .all()
    )

    latest: dict[str, object] = {}
    for e in events:
        if not e.properties:
            continue
        try:
            patient_id = json.loads(e.properties).get("patient_id")
        except (json.JSONDecodeError, AttributeError):
            continue
        if patient_id:
            latest[patient_id] = e.created_at

    return schemas.TriageAcknowledgementsOut(
        acknowledgements=[
            schemas.TriageAcknowledgement(patient_id=pid, acknowledged_at=ts)
            for pid, ts in latest.items()
        ]
    )
