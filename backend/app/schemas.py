from datetime import datetime
from pydantic import BaseModel


class UserBase(BaseModel):
    email: str
    full_name: str
    role: str


class UserCreate(UserBase):
    password: str


class UserResponse(UserBase):
    id: str
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






class MedicationCreate(BaseModel):
    case_id: str
    name: str
    dose: str
    schedule_text: str
    duration: str
    notes: str | None = None



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
