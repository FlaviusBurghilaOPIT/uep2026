from datetime import date

from app import models
from app.security import create_access_token


def test_trend_counts_checkins_by_feeling(client, db_session):
    clinician = models.User(email="c@t.com", full_name="C", role=models.UserRole.clinician)
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db_session.add(case)
    db_session.commit()

    db_session.add_all(
        [
            models.CheckIn(
                case_id=case.id, feeling=models.CheckInFeeling.great, checkin_date=date.today()
            ),
            models.CheckIn(
                case_id=case.id, feeling=models.CheckInFeeling.great, checkin_date=date.today()
            ),
            models.CheckIn(
                case_id=case.id, feeling=models.CheckInFeeling.bad, checkin_date=date.today()
            ),
        ]
    )
    db_session.commit()

    token = create_access_token(
        {"sub": clinician.id, "role": "clinician", "email": clinician.email}
    )
    response = client.get(
        f"/symptoms/patients/{patient.id}/symptoms/trend",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json() == {"great": 2, "ok": 0, "not_great": 0, "bad": 1}
