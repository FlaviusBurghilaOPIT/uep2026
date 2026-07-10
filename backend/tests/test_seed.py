from app import models
from app.scripts.seed import seed


def test_seed_creates_one_of_each_role(db_session):
    result = seed(db_session)

    assert result["admin"].role == models.UserRole.admin
    assert result["clinician"].role == models.UserRole.clinician
    assert result["patient"].role == models.UserRole.patient
    assert db_session.query(models.User).count() == 3


def test_seed_is_idempotent(db_session):
    seed(db_session)
    seed(db_session)

    assert db_session.query(models.User).count() == 3
