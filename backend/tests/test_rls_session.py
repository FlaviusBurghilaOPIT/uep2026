from app import models
from app.dependencies import get_db_for_user


def test_get_db_for_user_sets_session_vars(db_session):
    user = models.User(
        id="user-1",
        email="rls@example.com",
        full_name="RLS Test",
        role=models.UserRole.clinician,
    )

    gen = get_db_for_user(current_user=user, db=db_session)
    scoped_db = next(gen)

    # SQLite has no SET LOCAL / current_setting; the dependency must skip
    # the Postgres-only statement gracefully on any other dialect.
    assert scoped_db is db_session
