# Callback Handler

> OAuth 2.0 callback processor. Receives the authorization code from Cognito, validates the state JWT, exchanges the code for tokens, verifies tenant isolation, and issues the session cookie.

## Responsibility

The only service that handles real authentication tokens. Steps in order:

1. Decodes and validates the **state JWT** (CSRF protection)
2. Reads the tenant's `client_secret` from an environment variable
3. Exchanges the **authorization code** for `id_token`, `access_token`, and `refresh_token` via POST to Cognito
4. Extracts the email domain from the `id_token` (decode without signature verification — the JWT comes from Cognito, but signature is verified later by Istio)
5. Queries the **Discovery Service** to get the `tenant_id` for the domain
6. Compares the `tenant_id` from Discovery with the `tenant_id` in the state JWT — if they differ, returns 403
7. Issues the **session cookie** `session=<id_token>` with security attributes
8. Redirects to the `return_url` from the state JWT

## API

### `GET /callback`

Receives the Cognito redirect after user authentication.

**Query parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes | Authorization code issued by Cognito |
| `state` | string | yes | State JWT signed by `platform-frontend` |

**Responses:**

| Condition | Status | Response |
|---|---|---|
| Invalid or expired state JWT | 400 | Renders `error.html` |
| Tenant not configured in the service | 500 | Renders `error.html` |
| Code exchange failure | 400 | Renders `error.html` |
| Email domain not registered | 400 | Renders `error.html` |
| `tenant_id` from token ≠ `tenant_id` from state | 403 | Renders `error.html` |
| Success | 302 | Redirect to `return_url` + `Set-Cookie: session=<id_token>` |

### `GET /health`

```json
{"status": "ok"}
```

## State JWT validation

Implemented in `services/callback-handler/app/state.py` (`decode_state_token`):

- Decodes with `STATE_JWT_SECRET` (HS256)
- Expected fields: `tenant_id`, `client_id`, `return_url`, `nonce`
- `jwt.ExpiredSignatureError` and `jwt.InvalidTokenError` raise `InvalidStateError` → HTTP 400

## Code-for-tokens exchange — CognitoClient

Implemented in `services/callback-handler/app/cognito.py`.

`POST https://<COGNITO_DOMAIN>/oauth2/token` with:

```
grant_type=authorization_code
code=<code received from Cognito>
client_id=<client_id from state JWT>
redirect_uri=<CALLBACK_URL>
Authorization: Basic <base64(client_id:client_secret)>
```

Returns `CognitoTokens(id_token, access_token, refresh_token)`. HTTP response ≠ 200 raises `CognitoTokenExchangeError` → HTTP 400.

## Cross-domain validation — DomainValidator

Implemented in `services/callback-handler/app/domain_validator.py`.

Calls `GET <DISCOVERY_URL>/tenant?domain=<domain>` and returns the `tenant_id` from Discovery.

**Why this matters:** prevents a valid JWT from `customer1` from being used to access `customer2`. The email extracted from the token belongs to a domain, and that domain is registered to exactly one tenant. If the `tenant_id` returned by Discovery differs from the `tenant_id` in the state JWT, the callback returns 403.

## Per-tenant secrets

Each tenant has its own `client_secret` stored as an environment variable following the convention:

```
COGNITO_CLIENT_SECRET_<TENANT_ID_UPPERCASE>
```

Example:

```python
tenant_key = login_state.tenant_id.upper()  # "customer1" → "CUSTOMER1"
client_secret = os.environ[f"COGNITO_CLIENT_SECRET_{tenant_key}"]
```

Injected via Kubernetes Secret `callback-handler-secret` in the `auth` namespace.

!!! warning "Adding a tenant requires manual rollout"
    Adding a new tenant requires editing the `callback-handler-secret` Secret and rolling out the deployment. The production solution (AWS Secrets Manager or Parameter Store per tenant) is documented in [decisoes-tecnicas.md](../decisoes-tecnicas.md).

## Session cookie

```
Set-Cookie: session=<id_token>
  HttpOnly   — not accessible to JavaScript
  Secure     — HTTPS only
  SameSite=Lax — basic CSRF protection
  Domain=.wasp.silvios.me — valid for all platform subdomains
```

The cookie value is the Cognito `id_token` JWT. The Istio `RequestAuthentication` in the tenant namespace validates this JWT via the Cognito JWKS URI (RS256 signature verification).

## Environment variables

| Variable | Description |
|---|---|
| `COGNITO_DOMAIN` | Cognito hostname — **without `https://`** (e.g. `idp.wasp.silvios.me`) |
| `CALLBACK_URL` | URL registered as `redirect_uri` in the App Client |
| `DISCOVERY_URL` | Discovery Service base URL |
| `STATE_JWT_SECRET` | Shared secret with `platform-frontend` |
| `COGNITO_CLIENT_SECRET_CUSTOMER1` | App Client secret for customer1 |
| `COGNITO_CLIENT_SECRET_CUSTOMER2` | App Client secret for customer2 |
| `COGNITO_CLIENT_SECRET_<TENANT>` | One per tenant — `TENANT_ID_UPPERCASE` convention |

## Gotcha — pipe + heredoc conflicts with stdin

!!! warning "stdin"
    Pipe (`|`) and heredoc (`<<EOF`) compete for stdin. The heredoc wins. If a script needs to write a variable via heredoc **and** the Python code reads stdin, write the content to a temporary file and read it via `open()`.

## Kubernetes namespace and deploy

- **Namespace:** `auth`
- **Image:** `silviosilva/wasp-callback-handler:<sha>`
- **Secret:** `callback-handler-secret` (tenant client secrets + STATE_JWT_SECRET)
- **ConfigMap:** COGNITO_DOMAIN, CALLBACK_URL, DISCOVERY_URL

## Tests

```bash
cd services/callback-handler
.venv/bin/pytest tests/ -v
```

- `test_callback.py` — tests `GET /callback` with `CognitoClient` and `DomainValidator` overrides
- `test_state.py` — tests `decode_state_token` (valid, expired, invalid token)
