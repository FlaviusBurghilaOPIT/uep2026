from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user
from app.services.schedule_parser import (
    create_scheduled_reminders_for_medication,
    times_for_frequency,
)

router = APIRouter(
    prefix="/cases",
    tags=["cases"],
)


@router.post("/")
def create_case(
    case: schemas.CaseCreate,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    new_case = models.Case(
        clinician_id=current_user.id,
        patient_id=case.patient_id,
        surgery_type=case.surgery_type,
        surgery_date=case.surgery_date,
        emergency_contact_name=case.emergency_contact_name or current_user.full_name,
        emergency_contact_phone=case.emergency_contact_phone,
    )

    db.add(new_case)
    db.commit()
    db.refresh(new_case)

    return new_case


@router.get("/", response_model=list[schemas.CaseResponse])
def list_cases(
    db: Session = Depends(get_db_for_user), current_user: models.User = Depends(get_current_user)
):

    cases = db.query(models.Case).filter(models.Case.clinician_id == current_user.id).all()

    return cases


@router.get("/{case_id}", response_model=schemas.CaseResponse)
def get_case(
    case_id: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    case = (
        db.query(models.Case)
        .filter(models.Case.id == case_id, models.Case.clinician_id == current_user.id)
        .first()
    )

    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return case


@router.delete("/{case_id}")
def delete_case(
    case_id: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    case = (
        db.query(models.Case)
        .filter(models.Case.id == case_id, models.Case.clinician_id == current_user.id)
        .first()
    )

    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    db.delete(case)
    db.commit()

    return {"message": "Case deleted"}


@router.get("/{case_id}/medications", response_model=list[schemas.MedicationResponse])
def get_case_medications(
    case_id: str,
    include_discontinued: bool = False,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    query = db.query(models.Medication).filter(models.Medication.case_id == case_id)
    if not include_discontinued:
        query = query.filter(models.Medication.discontinued_at.is_(None))
    medications = query.all()

    result = []
    for m in medications:
        times = times_for_frequency(m.schedule_text)
        freq = (
            schemas.FrequencyCode(m.schedule_text)
            if m.schedule_text in schemas.FrequencyCode.__members__
            else schemas.FrequencyCode.QD
        )
        result.append(
            schemas.MedicationResponse(
                id=m.id,
                case_id=m.case_id,
                name=m.name,
                dose=m.dose,
                frequency=freq,
                schedule_times=[t.strftime("%H:%M") for t in times],
                duration=m.duration,
                notes=m.notes,
                created_at=m.created_at,
                scheduled_reminders=[
                    schemas.ReminderResponse(
                        id=r.id,
                        medication_id=r.medication_id,
                        scheduled_time=r.scheduled_time,
                        status=r.status,
                        created_at=r.created_at,
                    )
                    for r in m.scheduled_reminders
                ],
            )
        )
    return result


@router.post("/{case_id}/medications", response_model=schemas.MedicationResponse)
def create_case_medication(
    case_id: str,
    medication: schemas.MedicationCreate,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):

    case = (
        db.query(models.Case)
        .filter(models.Case.id == case_id, models.Case.clinician_id == current_user.id)
        .first()
    )

    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    new_medication = models.Medication(
        case_id=case_id,
        name=medication.name,
        dose=medication.dose,
        schedule_text=medication.frequency.value,
        duration=medication.duration,
        notes=medication.notes,
    )

    db.add(new_medication)
    db.flush()

    create_scheduled_reminders_for_medication(db, new_medication)

    db.commit()
    db.refresh(new_medication)

    times = times_for_frequency(new_medication.schedule_text)
    schedule_times_str = [t.strftime("%H:%M") for t in times]

    return schemas.MedicationResponse(
        id=new_medication.id,
        case_id=new_medication.case_id,
        name=new_medication.name,
        dose=new_medication.dose,
        frequency=schemas.FrequencyCode(new_medication.schedule_text),
        schedule_times=schedule_times_str,
        duration=new_medication.duration,
        notes=new_medication.notes,
        created_at=new_medication.created_at,
        scheduled_reminders=[
            schemas.ReminderResponse(
                id=r.id,
                medication_id=r.medication_id,
                scheduled_time=r.scheduled_time,
                status=r.status,
                created_at=r.created_at,
            )
            for r in new_medication.scheduled_reminders
        ],
    )


@router.get("/{case_id}/emergency-contact")
def get_emergency_contact(
    case_id: str,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(get_current_user),
):
    case = db.query(models.Case).filter(models.Case.id == case_id).first()

    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return {
        "name": case.emergency_contact_name,
        "phone": case.emergency_contact_phone,
    }
