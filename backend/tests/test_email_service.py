import logging
from unittest.mock import MagicMock

from app.services.email_service import EmailService


def test_send_patient_code_dry_run_logs_when_no_aws_region(monkeypatch, caplog):
    monkeypatch.delenv("AWS_REGION", raising=False)
    service = EmailService()

    with caplog.at_level(logging.INFO):
        service.send_patient_code("patient@example.com", "123456")

    assert service.dry_run is True
    assert any(
        "123456" in record.message and "patient@example.com" in record.message
        for record in caplog.records
    )


def test_send_patient_code_swallows_ses_failure_and_logs_warning(caplog):
    service = EmailService()
    service.dry_run = False
    service.ses_client = MagicMock()
    service.ses_client.send_email.side_effect = Exception("SES is down")

    with caplog.at_level(logging.WARNING):
        # Must not raise: email delivery is best-effort.
        service.send_patient_code("patient@example.com", "123456")

    service.ses_client.send_email.assert_called_once()
    assert any(
        "patient@example.com" in record.message and "SES is down" in record.message
        for record in caplog.records
    )
