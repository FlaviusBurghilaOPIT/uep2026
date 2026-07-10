from app.models import UserRole


def test_user_role_has_admin():
    assert UserRole.admin.value == "admin"
    assert set(r.value for r in UserRole) == {"admin", "clinician", "patient"}
