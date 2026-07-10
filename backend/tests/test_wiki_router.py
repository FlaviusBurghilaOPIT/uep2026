import json

from app import models
from app.security import create_access_token


def _clinician_headers(db_session):
    clinician = models.User(email="c@t.com", full_name="C", role=models.UserRole.clinician)
    db_session.add(clinician)
    db_session.commit()
    db_session.refresh(clinician)
    token = create_access_token(
        {"sub": clinician.id, "role": "clinician", "email": clinician.email}
    )
    return clinician, {"Authorization": f"Bearer {token}"}


def _patient_headers(db_session):
    patient = models.User(email="pat-wiki@t.com", full_name="Pat", role=models.UserRole.patient)
    db_session.add(patient)
    db_session.commit()
    db_session.refresh(patient)
    token = create_access_token({"sub": patient.id, "role": "patient", "email": patient.email})
    return patient, {"Authorization": f"Bearer {token}"}


def test_patient_cannot_generate_article(client, db_session):
    _, headers = _patient_headers(db_session)

    response = client.post("/wiki/generate?surgery_type=knee", headers=headers)

    assert response.status_code == 403


def test_generate_aggregates_recommendations_for_surgery_type(client, db_session):
    clinician, headers = _clinician_headers(db_session)
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add(patient)
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db_session.add(case)
    db_session.commit()

    db_session.add(models.Recommendation(case_id=case.id, text="Elevate the leg for 3 days."))
    db_session.commit()

    response = client.post("/wiki/generate?surgery_type=knee", headers=headers)

    assert response.status_code == 200
    body = response.json()
    assert body["surgery_type"] == "knee"
    assert body["status"] == "draft"
    assert "Elevate the leg for 3 days." in body["content_md"]
    assert json.loads(body["source_case_ids"]) == [case.id]


def test_index_lists_by_surgery_type(client, db_session):
    _, headers = _clinician_headers(db_session)
    article = models.WikiArticle(surgery_type="hip", content_md="content", source_case_ids="[]")
    db_session.add(article)
    db_session.commit()

    response = client.get("/wiki", headers=headers)

    assert response.status_code == 200
    assert any(a["surgery_type"] == "hip" for a in response.json())


def test_patch_approves_article(client, db_session):
    clinician, headers = _clinician_headers(db_session)
    article = models.WikiArticle(
        surgery_type="hip", content_md="draft content", source_case_ids="[]"
    )
    db_session.add(article)
    db_session.commit()
    db_session.refresh(article)

    response = client.patch(
        f"/wiki/{article.id}",
        json={"status": "approved"},
        headers=headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "approved"
    assert body["approved_by"] == clinician.id
