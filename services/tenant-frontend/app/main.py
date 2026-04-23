import logging
import os
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.session import decode_session

# ── Logging ──────────────────────────────────────────────────────────────────
_log_level = getattr(logging, os.getenv("LOG_LEVEL", "INFO").upper(), logging.INFO)
logging.basicConfig(level=_log_level)
logging.getLogger().setLevel(_log_level)

_logger = logging.getLogger(__name__)

# ── Config ───────────────────────────────────────────────────────────────────
HTTPBIN_URL = os.getenv("HTTPBIN_URL", "http://httpbin.wasp.local:32080")
PLATFORM_URL = os.getenv("PLATFORM_URL", "https://wasp.silvios.me")
CUSTOMER1_URL = os.getenv("CUSTOMER1_URL", "https://customer1.wasp.silvios.me")
CUSTOMER2_URL = os.getenv("CUSTOMER2_URL", "https://customer2.wasp.silvios.me")
IDP_LOGOUT_URL = os.getenv("IDP_LOGOUT_URL", "")
LOGOUT_CALLBACK_URL = os.getenv("LOGOUT_CALLBACK_URL", "")
IDP_CLIENT_ID = os.getenv("IDP_CLIENT_ID", "")
IDP_LOGOUT_REDIRECT_PARAM = os.getenv("IDP_LOGOUT_REDIRECT_PARAM", "post_logout_redirect_uri")

# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(title="WASP Tenant Frontend", version="1.0.0")

_static_dir = Path(__file__).parent / "static"
_templates_dir = Path(__file__).parent / "templates"

app.mount("/static", StaticFiles(directory=_static_dir, follow_symlink=True), name="static")
templates = Jinja2Templates(directory=_templates_dir)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _require_session(request: Request) -> dict | None:
    """Return claims dict or None (caller must redirect to PLATFORM_URL on None)."""
    return decode_session(request)


# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.get("/")
def home(request: Request):
    claims = _require_session(request)
    if claims is None:
        return RedirectResponse(url=PLATFORM_URL, status_code=302)

    return templates.TemplateResponse(
        request=request,
        name="home.html",
        context={
            "name": claims.get("name", "User"),
            "email": claims.get("email", ""),
            "tenant_id": claims.get("custom:tenant_id", ""),
        },
    )


@app.get("/test")
def test_page(request: Request):
    claims = _require_session(request)
    if claims is None:
        return RedirectResponse(url=PLATFORM_URL, status_code=302)

    tenant_id = claims.get("custom:tenant_id", "")
    session_token = request.cookies.get("session", "")

    def _curl(url: str, *, with_jwt: bool = True) -> str:
        parts = ["curl -i"]
        if with_jwt and session_token:
            parts.append(f"  -H 'Authorization: Bearer {session_token}'")
        parts.append(f"  '{url}'")
        return " \\\n".join(parts)

    def _case(label, name, url, expected, *, with_jwt: bool = True, group: str = ""):
        return {
            "label":    label,
            "name":     name,
            "url":      url,
            "expected": expected,
            "with_jwt": with_jwt,
            "curl_cmd": _curl(url, with_jwt=with_jwt),
            "group":    group,
        }

    is_c1 = tenant_id == "customer1"

    test_cases = [
        _case("httpbin",           "Public httpbin endpoint",            f"{HTTPBIN_URL}/get",           200,                   group="Own Tenant"),
        _case("customer1-health",  "Own tenant health check",            f"{CUSTOMER1_URL}/health",      200, with_jwt=False,   group="Own Tenant"   if is_c1 else "Cross-Tenant"),
        _case("customer2-health",  "Foreign tenant health check",        f"{CUSTOMER2_URL}/health",      200, with_jwt=False,   group="Cross-Tenant" if is_c1 else "Own Tenant"),
        _case("customer1-httpbin", "Authenticated request to own tenant",     f"{CUSTOMER1_URL}/httpbin/get", 200 if is_c1 else 403, group="Own Tenant"   if is_c1 else "Cross-Tenant"),
        _case("customer2-httpbin", "Authenticated request to foreign tenant", f"{CUSTOMER2_URL}/httpbin/get", 200 if not is_c1 else 403, group="Cross-Tenant" if is_c1 else "Own Tenant"),
    ]

    return templates.TemplateResponse(
        request=request,
        name="test.html",
        context={
            "test_cases":  test_cases,
            "jwt_token":   session_token,
            "name":        claims.get("name", "User"),
            "tenant_id":   tenant_id,
        },
    )


@app.get("/profile")
def profile(request: Request):
    claims = _require_session(request)
    if claims is None:
        return RedirectResponse(url=PLATFORM_URL, status_code=302)

    priority_keys = ["name", "email", "custom:tenant_id", "sub"]
    priority = [(k, claims[k]) for k in priority_keys if k in claims]
    rest = [(k, v) for k, v in claims.items() if k not in priority_keys]

    return templates.TemplateResponse(
        request=request,
        name="profile.html",
        context={
            "priority_claims": priority,
            "other_claims": rest,
            "name": claims.get("name", "User"),
            "tenant_id": claims.get("custom:tenant_id", ""),
        },
    )


@app.get("/logout")
def logout(request: Request):
    if IDP_LOGOUT_URL and LOGOUT_CALLBACK_URL:
        from urllib.parse import urlencode
        params = {IDP_LOGOUT_REDIRECT_PARAM: LOGOUT_CALLBACK_URL}
        id_token = request.cookies.get("session")
        if id_token:
            params["id_token_hint"] = id_token
        if IDP_CLIENT_ID:
            params["client_id"] = IDP_CLIENT_ID
        return RedirectResponse(url=f"{IDP_LOGOUT_URL}?{urlencode(params)}", status_code=302)
    return _clear_session_redirect(PLATFORM_URL)


@app.get("/logout/callback")
def logout_callback():
    return _clear_session_redirect(PLATFORM_URL)


def _clear_session_redirect(url: str):
    cookie_domain = os.getenv("COOKIE_DOMAIN", ".wasp.silvios.me")
    cookie_secure = os.getenv("COOKIE_SECURE", "true").lower() != "false"
    response = RedirectResponse(url=url, status_code=302)
    response.delete_cookie(
        key="session",
        domain=cookie_domain,
        path="/",
        secure=cookie_secure,
        httponly=True,
        samesite="lax",
    )
    return response
