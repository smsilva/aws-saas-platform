from starlette.requests import Request

from app.session import decode_session


def _request_with_cookie(value: str) -> Request:
    scope = {
        "type": "http",
        "headers": [(b"cookie", f"session={value}".encode())],
    }
    return Request(scope)


def test_decode_session_returns_none_when_no_cookie():
    scope = {"type": "http", "headers": []}
    result = decode_session(Request(scope))
    assert result is None


def test_decode_session_returns_none_for_invalid_jwt():
    result = decode_session(_request_with_cookie("not-a-valid-jwt"))
    assert result is None
