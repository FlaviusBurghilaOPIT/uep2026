from datetime import datetime, time, timedelta
from typing import Final
import re
from sqlalchemy.orm import Session
from app import models


FREQUENCY_TIMES: Final[dict[str, list[time]]] = {
    "QD":  [time(8, 0)],
    "BID": [time(8, 0), time(20, 0)],
    "TID": [time(8, 0), time(13, 0), time(20, 0)],
    "QID": [time(8, 0), time(12, 0), time(16, 0), time(20, 0)],
    "PRN": [],
}


def times_for_frequency(frequency: str) -> list[time]:
    """Returns default UTC reminder times for a FrequencyCode. Never raises."""
    return FREQUENCY_TIMES.get(frequency.upper(), [time(8, 0)])


def parse_duration_days(duration: str | None) -> int:
    """
    Parses a duration string to determine total number of days.
    - e.g. '7 days' -> 7
    - e.g. '2 weeks' -> 14
    - Default to 7 days if missing or unparseable.
    """
    if not duration:
        return 7

    st = duration.lower().strip()

    week_match = re.search(r"(\d+)\s*week", st)
    if week_match:
        try:
            return int(week_match.group(1)) * 7
        except ValueError:
            pass

    day_match = re.search(r"(\d+)", st)
    if day_match:
        try:
            val = int(day_match.group(1))
            return val if val > 0 else 7
        except ValueError:
            pass

    return 7


def create_scheduled_reminders_for_medication(
    db: Session, medication: models.Medication
) -> list[models.ScheduledReminder]:
    """
    Generates ScheduledReminder DB records for each day of duration.
    Uses times_for_frequency() — no regex, no language parsing.
    Stores scheduled_time in UTC naive datetime.
    """
    times = times_for_frequency(medication.schedule_text)
    days = parse_duration_days(medication.duration)

    if not times:
        return []   # PRN — no reminders

    start_date = datetime.utcnow().date()
    reminders = []

    for day_offset in range(days):
        day_date = start_date + timedelta(days=day_offset)
        for t in times:
            scheduled_dt = datetime.combine(day_date, t)
            reminder = models.ScheduledReminder(
                medication_id=medication.id,
                scheduled_time=scheduled_dt,
                status="pending",
            )
            db.add(reminder)
            reminders.append(reminder)

    return reminders
