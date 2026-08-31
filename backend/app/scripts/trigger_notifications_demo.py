"""
RemoteCare Pro — Notification Trigger & Verification Script
Located next to seed scripts: backend/app/scripts/trigger_notifications_demo.py

Usage:
    # 1. Trigger via live running API (port 8000 / default):
    python3.11 app/scripts/trigger_notifications_demo.py --api-url http://localhost:8000

    # 2. Trigger with custom title and body:
    python3.11 app/scripts/trigger_notifications_demo.py --title "Medication Reminder" --body "Time for Ibuprofen 400mg"

    # 3. Direct service execution (offline DB):
    python3.11 app/scripts/trigger_notifications_demo.py --direct-db
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

# Ensure backend root is in sys.path
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

# Normalize database URL if running directly on host outside docker network
db_url = os.getenv("DATABASE_URL", "")
if "@db:" in db_url and not os.path.exists("/.dockerenv"):
    os.environ["DATABASE_URL"] = db_url.replace("@db:", "@localhost:")

from app.database import SessionLocal
from app import models
from app.services.sns_push_service import SNSPushService


def _http_request(url: str, method: str = "GET", data: dict | None = None, headers: dict | None = None) -> tuple[int, dict | str]:
    headers = headers or {}
    encoded_data = None
    if data is not None:
        encoded_data = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            status = response.status
            body = response.read().decode("utf-8")
            try:
                return status, json.loads(body)
            except Exception:
                return status, body
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, body
    except Exception as e:
        raise e


def trigger_via_api(
    api_url: str = "http://localhost:8000",
    clinician_email: str = "clinician@example.com",
    clinician_password: str = "CarePro#2026!Secure",
    patient_email: str = "patient@example.com",
    title: str = "Medication Reminder",
    body: str = "Time to take your scheduled Ibuprofen 400 mg (with water/food).",
):
    print("=" * 70)
    print("🔔 REMOTECARE PRO — NOTIFICATION TRIGGER DEMO (API CLIENT)")
    print("=" * 70)

    # 1. Clinician Authentication
    print(f"\n[1/3] Authenticating as Clinician: {clinician_email}...")
    try:
        status, login_res = _http_request(
            f"{api_url}/auth/login",
            method="POST",
            data={"email": clinician_email, "password": clinician_password},
        )
        if status != 200:
            print(f"  ❌ Clinician login failed: {status} - {login_res}")
            return False
        
        token = login_res["access_token"]
        print("  ✅ Clinician JWT acquired.")
    except Exception as e:
        print(f"  ❌ Connection error connecting to {api_url}: {e}")
        print("  💡 Tip: Ensure docker containers / backend server is running on port 8000.")
        return False

    # 2. Find Patient Target
    print(f"\n[2/3] Resolving Target Patient ({patient_email})...")
    headers = {"Authorization": f"Bearer {token}"}
    status, cases_res = _http_request(f"{api_url}/cases", headers=headers)
    
    target_user_id = None
    target_name = "Sarah Mitchell"
    
    if status == 200 and isinstance(cases_res, list):
        for c in cases_res:
            p_id = c.get("patient_id")
            if p_id:
                target_user_id = p_id
                target_name = f"Patient ({c.get('surgery_type', 'Post-Surgery')})"
                break

    # Fallback to direct DB lookup if cases list was empty
    if not target_user_id:
        try:
            with SessionLocal() as db:
                patient = db.query(models.User).filter(models.User.email == patient_email).first()
                if patient:
                    target_user_id = patient.id
                    target_name = patient.full_name
        except Exception:
            pass

    if not target_user_id:
        print("  ❌ No patient user found in database. Run seed_data.py first.")
        return False

    print(f"  ✅ Target resolved: {target_name} [ID: {target_user_id}]")

    # 3. Dispatch Notification
    print(f"\n[3/3] Dispatching Test Notification via POST /notifications/send-test...")
    payload = {
        "target_user_id": target_user_id,
        "title": title,
        "body": body,
    }
    
    status, res = _http_request(f"{api_url}/notifications/send-test", method="POST", data=payload, headers=headers)
    print(f"  Response Status: {status}")
    print(f"  Response Data: {json.dumps(res, indent=2) if isinstance(res, dict) else res}")
    
    if status == 200:
        print("\n🎉 NOTIFICATION DISPATCHED SUCCESSFULLY!")
        print("Mobile Behavior:")
        print("  • If device token is registered: APNS/FCM sends push with interactive 'Take Dose' & 'Snooze' actions.")
        print("  • In dev/dry-run: Payload logged cleanly without requiring active AWS SNS production credentials.")
        return True
    return False


def trigger_direct_db(
    patient_email: str = "patient@example.com",
    title: str = "Medication Reminder",
    body: str = "Time to take your scheduled Ibuprofen 400 mg.",
):
    print("=" * 70)
    print("🔔 REMOTECARE PRO — DIRECT SERVICE NOTIFICATION TRIGGER")
    print("=" * 70)
    
    try:
        with SessionLocal() as db:
            patient = db.query(models.User).filter(models.User.email == patient_email).first()
            if not patient:
                print(f"❌ Patient {patient_email} not found in database. Run seed_data.py first.")
                return False

            print(f"✅ Found Patient: {patient.full_name} [ID: {patient.id}]")
            service = SNSPushService(db)
            
            result = service.send_push(
                user_id=patient.id,
                title=title,
                body=body,
                data={"action": "take_dose", "medication_name": "Ibuprofen 400 mg"},
            )
            print("\nService Execution Result:")
            print(json.dumps(result, indent=2))
            print("\n🎉 DIRECT NOTIFICATION SERVICE EXECUTION COMPLETE!")
            return True
    except Exception as e:
        print(f"❌ Database connection error: {e}")
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Trigger test notifications for RemoteCare Pro demo")
    parser.add_argument("--api-url", default="http://localhost:8000", help="Base URL of FastAPI backend")
    parser.add_argument("--direct-db", action="store_true", help="Execute directly via DB service (no HTTP)")
    parser.add_argument("--title", default="Medication Reminder: Ibuprofen 400 mg", help="Notification title")
    parser.add_argument("--body", default="Scheduled for 08:00 AM. Tap to log as taken.", help="Notification body")
    parser.add_argument("--patient-email", default="patient@example.com", help="Patient recipient email")
    args = parser.parse_args()

    if args.direct_db:
        trigger_direct_db(patient_email=args.patient_email, title=args.title, body=args.body)
    else:
        # Try API first, fallback to direct DB if server not currently listening
        success = trigger_via_api(
            api_url=args.api_url,
            patient_email=args.patient_email,
            title=args.title,
            body=args.body,
        )
        if not success:
            print("\nRetrying via direct database service...")
            trigger_direct_db(patient_email=args.patient_email, title=args.title, body=args.body)
