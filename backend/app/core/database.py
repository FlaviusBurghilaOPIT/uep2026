"""Core database module - re-exports unified engine and SessionLocal from app.database."""
from app.database import DATABASE_URL, SessionLocal, engine, get_db, init_db

__all__ = ["DATABASE_URL", "SessionLocal", "engine", "get_db", "init_db"]

