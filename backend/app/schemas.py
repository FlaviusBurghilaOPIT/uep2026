from datetime import datetime
import enum

from pydantic import BaseModel


class FrequencyCode(str, enum.Enum):
    QD  = "QD"
    BID = "BID"
    TID = "TID"
    QID = "QID"
    PRN = "PRN"



class UserCreate(BaseModel):
    email: str
    full_name: str
    password: str


class UserResponse(BaseModel):
    id: str
    email: str
    full_name: str
    role: str
    status: str | None = None
    phone: str | None = None
    date_of_birth: str | None = None
    invite_code: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class PatientInviteRequest(BaseModel):
    email: str
    full_name: str
    surgery_type: str
    emergency_contact_phone: str | None = None


class PatientInviteResponse(BaseModel):
    patient_id: str
    invite_code: str
    email: str
    full_name: str


class VerifyInviteRequest(BaseModel):
    email: str
    invite_code: str


class VerifyInviteResponse(BaseModel):
    email: str
    full_name: str
    invite_code: str
    status: str


class CompleteOnboardingRequest(BaseModel):
    email: str
    invite_code: str
    password: str
    date_of_birth: str
    phone: str


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


class MedicationCreate(BaseModel):
    name:      str
    dose:      str
    frequency: FrequencyCode
    duration:  str
    notes:     str | None = None


class MedicationResponse(BaseModel):
    id:             str
    case_id:        str
    name:           str
    dose:           str
    frequency:      FrequencyCode
    schedule_times: list[str] = []
    duration:       str
    notes:          str | None
    created_at:     datetime
    scheduled_reminders: list[ReminderResponse] = []

    class Config:
        from_attributes = True


class ChatRequest(BaseModel):
    case_id: str
    message: str


class ChatResponse(BaseModel):
    reply: str
    in_scope: bool = True
    escalate: bool = False


class FDADrugInfoResponse(BaseModel):
    drug_name: str
    summary: str
    source: str


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


class RecommendationCreate(BaseModel):
    text: str | None = None
    content: str | None = None


class RecommendationResponse(BaseModel):
    id: str
    case_id: str
    text: str
    content: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class DeviceTokenRegisterRequest(BaseModel):
    token: str
    platform: str = "ios"


class DeviceTokenResponse(BaseModel):
    id: int
    user_id: str
    token: str
    platform: str
    is_active: bool
    updated_at: datetime

    class Config:
        from_attributes = True


class SendTestPushRequest(BaseModel):
    user_id: str
    title: str
    body: str
    data_payload: dict | None = None


