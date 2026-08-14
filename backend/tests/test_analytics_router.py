import json

from app import models
from app.security import create_access_token


def _clinician(db_session):
    clinician = models.User(email="c@t.com", full_name="Dr C", role=models.UserRole.clinician)
    db_session.add(clinician)
    db_session.commit()
    return clinician


def _headers(user):
    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"Authorization": f"Bearer {token}"}


def test_track_event_records_allowed_event(client, db_session):
    clinician = _clinician(db_session)

    response = client.post(
        "/analytics/events",
        json={
            "event_name": "web.triage.exception_viewed",
            "properties": {"patient_id": "p-1", "severity": "red"},
        },
        headers=_headers(clinician),
    )

    assert response.status_code == 201
    stored = db_session.query(models.AnalyticsEvent).one()
    assert stored.event_name == "web.triage.exception_viewed"
    assert json.loads(stored.properties) == {"patient_id": "p-1", "severity": "red"}


def test_track_event_rejects_unknown_event(client, db_session):
    clinician = _clinician(db_session)

    response = client.post(
        "/analytics/events",
        json={"event_name": "web.engagement.time_on_page"},
        headers=_headers(clinician),
    )

    assert response.status_code == 400


def test_track_event_rejects_phi_properties(client, db_session):
    clinician = _clinician(db_session)

    response = client.post(
        "/analytics/events",
        json={
            "event_name": "web.case.created",
            "properties": {"patient_name": "Maria Rossi"},
        },
        headers=_headers(clinician),
    )

    assert response.status_code == 400


def test_triage_response_stats_computes_median(client, db_session):
    from datetime import datetime

    clinician = _clinician(db_session)
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add(patient)
    db_session.commit()

    viewed_at = datetime(2026, 7, 25, 10, 0, 0)
    db_session.add(
        models.AnalyticsEvent(
            event_name="web.triage.exception_viewed",
            actor_id=clinician.id,
            properties=json.dumps({"patient_id": patient.id, "severity": "red"}),
            created_at=viewed_at,
        )
    )
    db_session.add(
        models.TriageResolution(
            patient_id=patient.id,
            clinician_id=clinician.id,
            outreach_method="phone_call",
            clinical_note="Called the patient.",
            resolved_at=datetime(2026, 7, 25, 10, 0, 45),
        )
    )
    db_session.commit()

    response = client.get("/analytics/triage-response", headers=_headers(clinician))

    assert response.status_code == 200
    body = response.json()
    assert body["median_seconds"] == 45.0
    assert body["samples"] == 1
    assert body["resolutions_total"] == 1


def test_triage_response_stats_empty(client, db_session):
    clinician = _clinician(db_session)

    response = client.get("/analytics/triage-response", headers=_headers(clinician))

    assert response.status_code == 200
    assert response.json() == {
        "median_seconds": None,
        "samples": 0,
        "resolutions_total": 0,
    }
