import enum
from datetime import date, datetime, timezone

from pydantic import BaseModel, field_serializer

from app.models import DoseStatus


class FrequencyCode(str, enum.Enum):
    QD  = "QD"
    BID = "BID"
    TID = "TID"
    QID = "QID"
    PRN = "PRN"


class IntentCategory(str, enum.Enum):
    general_question    = "general_question"
    medication_query    = "medication_query"
    dose_change_request = "dose_change_request"
    diagnosis_request   = "diagnosis_request"



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


class TriageRosterPage(BaseModel):
    """Paginated query-by-example roster for the triage dashboard."""

    items: list[UserResponse]
    total: int
    page: int
    size: int


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
    date_of_birth: str
    phone: str


class PatientRequestCodeRequest(BaseModel):
    email: str


class PatientRequestCodeResponse(BaseModel):
    message: str = "If that email exists, a code was sent."


class PatientVerifyCodeRequest(BaseModel):
    email: str
    code: str


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
    case_id:         str
    message:         str
    intent_category: IntentCategory = IntentCategory.general_question


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




class TriageResolveRequest(BaseModel):
    outreach_method: str
    clinical_note: str


class TriageResolutionResponse(BaseModel):
    id: str
    patient_id: str
    clinician_id: str
    outreach_method: str
    clinical_note: str
    resolved_at: datetime

    class Config:
        from_attributes = True


class TriageResolutionLatest(BaseModel):
    patient_id: str
    resolved_at: datetime


class DoseLogDetailResponse(BaseModel):
    id: str
    scheduled_reminder_id: str
    status: str
    logged_at: datetime | None
    medication_name: str | None
    scheduled_time: datetime | None


class AnalyticsEventIn(BaseModel):
    event_name: str
    properties: dict | None = None


class TriageResponseStats(BaseModel):
    median_seconds: float | None
    samples: int
    resolutions_total: int


# --- Adherence pipeline (spec: ai_specs/2026-07-26-adherence-pipeline-backend-spec.md §6) ---


class SlotState(str, enum.Enum):
    upcoming = "upcoming"
    due = "due"
    overdue = "overdue"
    missed = "missed"
    taken = "taken"
    skipped = "skipped"


class AgendaSlot(BaseModel):
    slot_id: str
    medication_id: str
    medication_name: str
    dose: str
    notes: str | None
    scheduled_time: datetime
    state: SlotState
    logged_at: datetime | None = None
    dose_log_id: str | None = None
    previous_status: DoseStatus | None = None

    @field_serializer("scheduled_time", "logged_at")
    def _serialize_as_utc_z(self, value: datetime | None) -> str | None:
        # Spec E2: stored naive datetimes are interpreted as UTC and
        # serialized with a trailing Z.
        if value is None:
            return None
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.isoformat().replace("+00:00", "Z")


class AgendaPrnMedication(BaseModel):
    medication_id: str
    medication_name: str
    dose: str
    notes: str | None = None


class AgendaResponse(BaseModel):
    date: date
    slots: list[AgendaSlot] = []
    prn: list[AgendaPrnMedication] = []


class AdhocLogRequest(BaseModel):
    medication_id: str
    status: DoseStatus
    taken_at: datetime | None = None
    idempotency_key: str


class AdhocLogResponse(BaseModel):
    slot: AgendaSlot
    dose_log: "DoseLogCorrectResponse"


class DoseLogCorrectRequest(BaseModel):
    status: DoseStatus


class DoseLogCorrectResponse(BaseModel):
    id: str
    scheduled_reminder_id: str
    status: DoseStatus
    previous_status: DoseStatus | None = None
    logged_at: datetime | None = None
    corrected_at: datetime | None = None
