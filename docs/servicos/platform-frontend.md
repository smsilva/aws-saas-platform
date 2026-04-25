# Platform Frontend

> Platform login frontend. Receives the user's email, queries the Discovery Service, and redirects to the Cognito Hosted UI for the corresponding tenant.

## Responsibility

User entry point. Works as an "IdP router": does not authenticate the user directly — it only discovers which IdP to use and initiates the OAuth 2.0 Authorization Code Flow by redirecting to the correct Cognito.

## Login flow

1. User accesses `https://wasp.silvios.me` → `GET /` renders `login.html`
2. User types the email and submits the form → `POST /login`
3. The service validates the email format and extracts the domain
4. Calls `GET /tenant?domain=<domain>` on the Discovery Service
5. Builds the state JWT with `tenant_id`, `client_id`, `return_url`, and `nonce` (expires in 10 min, HS256)
6. Builds the Cognito authorization URL with `identity_provider`, `scope`, `state`, `redirect_uri`
7. Returns `HTTP 302` → Cognito Hosted UI

## API

### `GET /`

Renders `login.html`. No authentication required.

### `POST /login`

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | string (form) | yes | User's email |

**Behavior:**

| Condition | Response |
|---|---|
| Email without `@` or without `.` in domain | Re-renders login with error message |
| Domain not found in Discovery | Re-renders login with error message |
| Domain found | `HTTP 302` → Cognito Hosted UI |

### `GET /health`

```json
{"status": "ok"}
```

## State JWT

The state JWT is the CSRF protection for the OAuth flow. Defined in `services/platform-frontend/app/auth.py`:

| Field | Type | Description |
|---|---|---|
| `tenant_id` | string | Tenant ID (e.g. `customer1`) |
| `client_id` | string | Cognito App Client ID for the tenant |
| `return_url` | string | Post-login destination URL (`https://<tenant_url>`) |
| `nonce` | string | 16 random urlsafe bytes — uniqueness per request |
| `exp` | timestamp | Expires in 10 minutes |

- **Algorithm:** HS256
- **Secret:** `STATE_JWT_SECRET` — shared with `callback-handler`

## Cognito authorization URL

Parameters built by `build_cognito_authorize_url()` in `auth.py`:

| Parameter | Value |
|---|---|
| `client_id` | Cognito App Client ID for the tenant |
| `identity_provider` | IdP name in Cognito (e.g. `Google`, `MicrosoftAD-Customer2`) |
| `redirect_uri` | `https://auth.wasp.silvios.me/callback` |
| `response_type` | `code` |
| `scope` | `openid email profile` |
| `state` | Signed state JWT |

URL built: `https://<COGNITO_DOMAIN>/oauth2/authorize?<params>`

## Environment variables

| Variable | Description |
|---|---|
| `DISCOVERY_URL` | Discovery Service base URL (e.g. `https://discovery.wasp.silvios.me`) |
| `COGNITO_DOMAIN` | Cognito hostname — **without `https://`** (e.g. `idp.wasp.silvios.me`) |
| `CALLBACK_URL` | OAuth callback URL (e.g. `https://auth.wasp.silvios.me/callback`) |
| `STATE_JWT_SECRET` | Shared secret with `callback-handler` |

!!! warning "`COGNITO_DOMAIN` without `https://`"
    The code in `auth.py` prepends the `https://` scheme when building the URL. If `COGNITO_DOMAIN` is `https://idp.wasp.silvios.me`, the generated redirect will be `https://https://idp...` and login will break.

## Kubernetes namespace and deploy

- **Namespace:** `platform`
- **Image:** `silviosilva/wasp-platform-frontend:<sha>`
- **ConfigMap:** `platform-frontend-config` (DISCOVERY_URL, COGNITO_DOMAIN, CALLBACK_URL)
- **Secret:** `platform-frontend-secret` (STATE_JWT_SECRET)

## Tests

```bash
cd services/platform-frontend
.venv/bin/pytest tests/ -v
```

- `test_login_page.py` — tests `GET /`, `POST /login` (invalid email, domain not found, domain found with correct redirect)
