"""
Remote CarePro — SQLAlchemy models
Golden loop entities: User -> Patient/Clinician, Case, Medication,
ScheduledReminder, DoseLog, Recommendation, CheckIn, ChatMessage.
"""

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    String,
    Text,
    DateTime,
    Enum,
    ForeignKey,
    Date,
)
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    mapped_column,
    relationship,
)


class Base(DeclarativeBase):
    pass


def gen_uuid() -> str:
    return str(uuid.uuid4())


class UserRole(str, enum.Enum):
    clinician = "clinician"
    patient = "patient"


class DoseStatus(str, enum.Enum):
    pending = "pending"
    taken = "taken"
    missed = "missed"
    skipped = "skipped"


class CheckInFeeling(str, enum.Enum):
    great = "great"
    ok = "ok"
    not_great = "not_great"
    bad = "bad"


class ChatRole(str, enum.Enum):
    user = "user"
    assistant = "assistant"


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    email: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String, nullable=False)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), nullable=False)

    password_hash: Mapped[str | None] = mapped_column(String, nullable=True)
    cognito_sub: Mapped[str | None] = mapped_column(String, unique=True, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    cases_as_clinician: Mapped[list["Case"]] = relationship(
        back_populates="clinician", foreign_keys="Case.clinician_id"
    )
    cases_as_patient: Mapped[list["Case"]] = relationship(
        back_populates="patient", foreign_keys="Case.patient_id"
    )


class Case(Base):
    __tablename__ = "cases"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    clinician_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    patient_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)

    surgery_type: Mapped[str] = mapped_column(String, nullable=False)
    status: Mapped[str] = mapped_column(String, default="active")

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    clinician: Mapped["User"] = relationship(
        back_populates="cases_as_clinician", foreign_keys=[clinician_id]
    )
    patient: Mapped["User"] = relationship(
        back_populates="cases_as_patient", foreign_keys=[patient_id]
    )

    medications: Mapped[list["Medication"]] = relationship(
        back_populates="case", cascade="all, delete-orphan"
    )
    recommendations: Mapped[list["Recommendation"]] = relationship(
        back_populates="case", cascade="all, delete-orphan"
    )
    checkins: Mapped[list["CheckIn"]] = relationship(
        back_populates="case", cascade="all, delete-orphan"
    )
    chat_messages: Mapped[list["ChatMessage"]] = relationship(
        back_populates="case", cascade="all, delete-orphan"
    )


class Medication(Base):
    __tablename__ = "medications"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    case_id: Mapped[str] = mapped_column(ForeignKey("cases.id"), nullable=False)

    name: Mapped[str] = mapped_column(String, nullable=False)
    dose: Mapped[str] = mapped_column(String, nullable=False)
    schedule_text: Mapped[str] = mapped_column(String, nullable=False)
    duration: Mapped[str] = mapped_column(String, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    case: Mapped["Case"] = relationship(back_populates="medications")
    scheduled_reminders: Mapped[list["ScheduledReminder"]] = relationship(
        back_populates="medication", cascade="all, delete-orphan"
    )


class ScheduledReminder(Base):
    __tablename__ = "scheduled_reminders"

    id: Mapped[str] = mapped_column(
        String,
        primary_key=True,
        default=gen_uuid
    )

    medication_id: Mapped[str] = mapped_column(
        ForeignKey("medications.id"),
        nullable=False
    )

    scheduled_time: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False
    )

    status: Mapped[str] = mapped_column(
        String,
        default="pending"
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    medication: Mapped["Medication"] = relationship(
        back_populates="scheduled_reminders"
    )
    dose_log: Mapped["DoseLog"] = relationship(
    back_populates="scheduled_reminder"
)

class DoseLog(Base):
    __tablename__ = "dose_logs"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    scheduled_reminder_id: Mapped[str] = mapped_column(
        ForeignKey("scheduled_reminders.id"), unique=True, nullable=False
    )
    status: Mapped[DoseStatus] = mapped_column(Enum(DoseStatus), default=DoseStatus.pending)
    logged_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    scheduled_reminder: Mapped["ScheduledReminder"] = relationship(back_populates="dose_log")


class Recommendation(Base):
    __tablename__ = "recommendations"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    case_id: Mapped[str] = mapped_column(ForeignKey("cases.id"), nullable=False)

    text: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    case: Mapped["Case"] = relationship(back_populates="recommendations")


class CheckIn(Base):
    __tablename__ = "checkins"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    case_id: Mapped[str] = mapped_column(ForeignKey("cases.id"), nullable=False)

    feeling: Mapped[CheckInFeeling] = mapped_column(Enum(CheckInFeeling), nullable=False)
    checkin_date: Mapped[Date] = mapped_column(Date, default=datetime.utcnow().date)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    case: Mapped["Case"] = relationship(back_populates="checkins")


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    case_id: Mapped[str] = mapped_column(ForeignKey("cases.id"), nullable=False)

    role: Mapped[ChatRole] = mapped_column(Enum(ChatRole), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    case: Mapped["Case"] = relationship(back_populates="chat_messages")
