from unittest.mock import patch, MagicMock

import httpx
import pytest

from app.domain_validator import DomainValidator, DomainValidationError

DISCOVERY_URL = "http://discovery.wasp.local:32080"


def test_get_tenant_for_domain_returns_tenant_id_on_success():
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"tenant_id": "customer1"}

    with patch("app.domain_validator.httpx.get", return_value=mock_response):
        validator = DomainValidator(DISCOVERY_URL)
        result = validator.get_tenant_for_domain("customer1.wasp.local")

    assert result == "customer1"


def test_get_tenant_for_domain_raises_on_404():
    mock_response = MagicMock()
    mock_response.status_code = 404

    with patch("app.domain_validator.httpx.get", return_value=mock_response):
        validator = DomainValidator(DISCOVERY_URL)
        with pytest.raises(DomainValidationError, match="not registered"):
            validator.get_tenant_for_domain("unknown.wasp.local")


def test_get_tenant_for_domain_raises_on_non_200_non_404():
    mock_response = MagicMock()
    mock_response.status_code = 503

    with patch("app.domain_validator.httpx.get", return_value=mock_response):
        validator = DomainValidator(DISCOVERY_URL)
        with pytest.raises(DomainValidationError, match="503"):
            validator.get_tenant_for_domain("customer1.wasp.local")


def test_get_tenant_for_domain_raises_on_request_error():
    with patch("app.domain_validator.httpx.get", side_effect=httpx.RequestError("connect failed")):
        validator = DomainValidator(DISCOVERY_URL)
        with pytest.raises(DomainValidationError, match="unreachable"):
            validator.get_tenant_for_domain("customer1.wasp.local")
