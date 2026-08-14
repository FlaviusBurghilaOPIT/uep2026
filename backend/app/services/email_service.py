import logging
import os

logger = logging.getLogger(__name__)


class EmailService:
    def __init__(self):
        self.aws_region = os.getenv("AWS_REGION")
        self.sender_address = os.getenv("SES_SENDER_ADDRESS", "no-reply@remotecarepro.local")

        if self.aws_region:
            try:
                import boto3

                self.ses_client = boto3.client("ses", region_name=self.aws_region)
                self.dry_run = False
            except Exception as e:
                logger.warning(f"Failed to initialize boto3 SES client: {e}. Falling back to dry-run.")
                self.ses_client = None
                self.dry_run = True
        else:
            self.ses_client = None
            self.dry_run = True

    def send_patient_code(self, email: str, code: str) -> None:
        subject = "Your RemoteCare Pro sign-in code"
        body = f"Your sign-in code is {code}. It expires in 15 minutes."

        if self.dry_run:
            logger.info(f"[DRY RUN] Would email code {code} to {email}: {subject}")
            return

        try:
            self.ses_client.send_email(
                Source=self.sender_address,
                Destination={"ToAddresses": [email]},
                Message={
                    "Subject": {"Data": subject},
                    "Body": {"Text": {"Data": body}},
                },
            )
        except Exception as e:
            # Email delivery is best-effort: the code is also visible via the
            # web UI display and dry-run/console logging in local dev, and
            # callers must not leak SES failures as request errors (that would
            # re-introduce an email-enumeration signal on request-code, or a
            # crash after the patient row is already committed on invite).
            logger.warning(f"Failed to send patient code email to {email}: {e}")
