from unittest.mock import patch, MagicMock

import httpx
import pytest

from app.discovery_client import DiscoveryClient, TenantInfo

BASE_URL = "http://discovery.wasp.local:32080"


def test_find_tenant_by_domain_returns_tenant_info_on_success():
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "tenant_id": "customer1",
        "tenant_url": "https://customer1.wasp.silvios.me",
        "client_id": "abc123client",
        "idp_name": "Google",
        "idp_pool_id": "us-east-1_ABC123",
    }
    mock_response.raise_for_status.return_value = None

    with patch("app.discovery_client.httpx.get", return_value=mock_response):
        client = DiscoveryClient(BASE_URL)
        result = client.find_tenant_by_domain("customer1.wasp.silvios.me")

    assert isinstance(result, TenantInfo)
    assert result.tenant_id == "customer1"


def test_find_tenant_by_domain_returns_none_on_404():
    mock_response = MagicMock()
    mock_response.status_code = 404

    with patch("app.discovery_client.httpx.get", return_value=mock_response):
        client = DiscoveryClient(BASE_URL)
        result = client.find_tenant_by_domain("unknown.wasp.silvios.me")

    assert result is None


def test_find_tenant_by_domain_returns_none_when_raise_for_status_raises():
    mock_response = MagicMock()
    mock_response.status_code = 503
    mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
        "service unavailable", request=MagicMock(), response=mock_response
    )

    with patch("app.discovery_client.httpx.get", return_value=mock_response):
        client = DiscoveryClient(BASE_URL)
        result = client.find_tenant_by_domain("customer1.wasp.silvios.me")

    assert result is None


def test_find_tenant_by_domain_returns_none_on_connect_error():
    with patch("app.discovery_client.httpx.get", side_effect=httpx.ConnectError("connection refused")):
        client = DiscoveryClient(BASE_URL)
        result = client.find_tenant_by_domain("customer1.wasp.silvios.me")

    assert result is None
