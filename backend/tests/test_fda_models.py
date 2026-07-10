from app.models import CaseFDAWarning, FDAWarning, FDAWarningStatus


def test_fda_warning_defaults_to_pending(db_session):
    warning = FDAWarning(drug_name="ibuprofen", summary="test", severity="moderate")
    db_session.add(warning)
    db_session.commit()
    db_session.refresh(warning)

    assert warning.status == FDAWarningStatus.pending
    assert warning.reviewed_by is None


def test_case_fda_warning_links_case_and_warning(db_session):
    from app import models

    clinician = models.User(email="c@t.com", full_name="C", role=models.UserRole.clinician)
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    warning = FDAWarning(drug_name="ibuprofen", summary="test", severity="moderate")
    db_session.add_all([case, warning])
    db_session.commit()

    link = CaseFDAWarning(case_id=case.id, fda_warning_id=warning.id)
    db_session.add(link)
    db_session.commit()
    db_session.refresh(link)

    assert link.case_id == case.id
    assert link.fda_warning_id == warning.id
