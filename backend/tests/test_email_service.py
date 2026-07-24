import logging

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
