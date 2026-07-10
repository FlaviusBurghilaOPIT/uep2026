from datetime import datetime

from pydantic import BaseModel


class UserCreate(BaseModel):
    email: str
    full_name: str
    password: str


class UserResponse(BaseModel):
    id: str
    email: str
    full_name: str
    role: str
    created_at: datetime

    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class CaseCreate(BaseModel):
    patient_id: str
    surgery_type: str
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None


class CaseResponse(BaseModel):
    id: str
    clinician_id: str
    patient_id: str
    surgery_type: str
    status: str
    emergency_contact_name: str | None
    emergency_contact_phone: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class MedicationCreate(BaseModel):
    name: str
    dose: str
    schedule_text: str
    duration: str
    notes: str | None = None


class MedicationResponse(BaseModel):
    id: str
    case_id: str
    name: str
    dose: str
    schedule_text: str
    duration: str
    notes: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class ReminderCreate(BaseModel):
    medication_id: str
    scheduled_time: datetime


class ReminderResponse(BaseModel):
    id: str
    medication_id: str
    scheduled_time: datetime
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class ChatRequest(BaseModel):
    case_id: str
    message: str


class ChatResponse(BaseModel):
    reply: str
    in_scope: bool = True
    escalate: bool = False


class FDAWarningResponse(BaseModel):
    id: str
    drug_name: str
    summary: str
    severity: str
    status: str
    created_at: datetime
    reviewed_by: str | None
    reviewed_at: datetime | None

    class Config:
        from_attributes = True


class WikiArticleResponse(BaseModel):
    id: str
    surgery_type: str
    content_md: str
    status: str
    source_case_ids: str
    created_at: datetime
    approved_by: str | None

    class Config:
        from_attributes = True


class WikiArticleUpdate(BaseModel):
    content_md: str | None = None
    status: str | None = None
