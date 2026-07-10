import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# docker-compose's .env points DATABASE_URL/MIGRATION_DATABASE_URL at the `db`
# service hostname, which only resolves inside the compose network. Running
# `pytest` directly on the host (outside docker) needs the same Postgres
# reached via localhost instead, since docker-compose publishes 5432:5432.
os.environ.setdefault(
    "DATABASE_URL", "postgresql://caredev:caredev@localhost:5432/remotecare"
)
os.environ.setdefault(
    "MIGRATION_DATABASE_URL", "postgresql://caredev:caredev@localhost:5432/remotecare"
)
os.environ.setdefault("POSTGRES_APP_PASSWORD", "dev-only-change-in-prod")

from app.database import get_db
from app.main import app
from app.models import Base


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()
