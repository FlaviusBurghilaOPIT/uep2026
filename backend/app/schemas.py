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


class CaseResponse(BaseModel):
    id: str
    clinician_id: str
    patient_id: str
    surgery_type: str
    status: str
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
