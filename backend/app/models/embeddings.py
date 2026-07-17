from sqlalchemy import Column, String, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from pgvector.sqlalchemy import Vector
from datetime import datetime
import uuid
from .base import Base

class Embedding(Base):
    __tablename__ = "embeddings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    content = Column(Text, nullable=False)      # the original text chunk
    source = Column(String, nullable=False)      # "NICE guidelines" / "case notes" / "FDA"
    source_type = Column(String, nullable=False) # "guideline" / "case_note" / "fda"
    surgery_type = Column(String, nullable=True) # "knee replacement" etc.
    embedding = Column(Vector(1536), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)