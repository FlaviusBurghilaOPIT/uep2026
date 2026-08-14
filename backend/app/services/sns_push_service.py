import json
import logging
import os
from datetime import datetime

from sqlalchemy.orm import Session

from app import models

logger = logging.getLogger(__name__)


class SNSPushService:
    def __init__(self, db: Session):
        self.db = db
        self.aws_region = os.getenv("AWS_REGION")
        self.sns_platform_arn = os.getenv("SNS_PLATFORM_APPLICATION_ARN")

        if self.aws_region:
            try:
                import boto3

                self.sns_client = boto3.client("sns", region_name=self.aws_region)
                self.dry_run = False
            except Exception as e:
                logger.warning(f"Failed to initialize boto3 SNS client: {e}. Falling back to dry-run.")
                self.sns_client = None
                self.dry_run = True
        else:
            self.sns_client = None
            self.dry_run = True

    def register_endpoint(self, user_id: str, token: str, platform: str) -> models.DeviceToken:
        """
        Registers or updates a device token for a given user.
        """
        platform_clean = platform.lower()
        if platform_clean not in ("ios", "android", "web"):
            platform_clean = "ios"

        device_token = (
            self.db.query(models.DeviceToken)
            .filter(models.DeviceToken.token == token)
            .first()
        )

        if device_token:
            device_token.user_id = user_id
            device_token.platform = platform_clean
            device_token.is_active = True
            device_token.updated_at = datetime.utcnow()
        else:
            device_token = models.DeviceToken(
                user_id=user_id,
                token=token,
                platform=platform_clean,
                is_active=True,
                updated_at=datetime.utcnow(),
            )
            self.db.add(device_token)

        self.db.commit()
        self.db.refresh(device_token)
        return device_token

    def build_apns_payload(self, title: str, body: str, data_payload: dict | None = None) -> str:
        payload = {
            "aps": {
                "alert": {
                    "title": title,
                    "body": body,
                },
                "sound": "default",
            }
        }
        if data_payload:
            payload.update(data_payload)
        return json.dumps(payload)

    def build_fcm_payload(self, title: str, body: str, data_payload: dict | None = None) -> str:
        payload = {
            "notification": {
                "title": title,
                "body": body,
            },
            "data": data_payload or {},
        }
        return json.dumps(payload)

    def build_sns_message(
        self, title: str, body: str, data_payload: dict | None = None
    ) -> str:
        apns_json = self.build_apns_payload(title, body, data_payload)
        fcm_json = self.build_fcm_payload(title, body, data_payload)

        message_dict = {
            "default": f"{title}: {body}",
            "APNS": apns_json,
            "APNS_SANDBOX": apns_json,
            "GCM": fcm_json,
            "FCM": fcm_json,
        }
        return json.dumps(message_dict)

    def send_push_notification(
        self,
        user_id: str,
        title: str,
        body: str,
        data_payload: dict | None = None,
    ) -> dict:
        """
        Sends a remote push notification to all active devices registered for a user.
        Falls back to dry-run simulation when AWS_REGION is omitted or boto3 client is unavailable.
        """
        active_tokens = (
            self.db.query(models.DeviceToken)
            .filter(
                models.DeviceToken.user_id == user_id,
                models.DeviceToken.is_active == True,
            )
            .all()
        )

        if not active_tokens:
            return {
                "sent": 0,
                "status": "no_active_tokens",
                "dry_run": self.dry_run,
                "results": [],
            }

        sns_message = self.build_sns_message(title, body, data_payload)
        results = []
        sent_count = 0

        for token_record in active_tokens:
            if self.dry_run or not self.sns_client:
                results.append(
                    {
                        "token": token_record.token,
                        "platform": token_record.platform,
                        "status": "dry_run_success",
                        "sns_message": json.loads(sns_message),
                    }
                )
                sent_count += 1
            else:
                try:
                    publish_kwargs = {
                        "TargetArn": token_record.token,
                        "Message": sns_message,
                        "MessageStructure": "json",
                    }
                    response = self.sns_client.publish(**publish_kwargs)
                    results.append(
                        {
                            "token": token_record.token,
                            "platform": token_record.platform,
                            "status": "sent",
                            "message_id": response.get("MessageId"),
                        }
                    )
                    sent_count += 1
                except Exception as e:
                    logger.error(f"SNS publish failed for token {token_record.token}: {e}")
                    token_record.is_active = False
                    self.db.commit()
                    results.append(
                        {
                            "token": token_record.token,
                            "platform": token_record.platform,
                            "status": "failed",
                            "error": str(e),
                        }
                    )

        return {
            "sent": sent_count,
            "dry_run": self.dry_run,
            "results": results,
        }
