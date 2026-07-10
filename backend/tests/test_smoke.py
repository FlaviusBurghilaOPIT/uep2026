def test_client_fixture_loads(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_health_db_endpoint_uses_shared_test_database(client):
    response = client.get("/health/db")
    assert response.status_code == 200
    assert response.json() == {"database": "connected"}
