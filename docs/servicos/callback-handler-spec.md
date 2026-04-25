# Callback Handler

## Purpose

Define the behavioral contracts for the OAuth 2.0 callback processor. This service is the only component that handles real authentication tokens: it validates the CSRF state, exchanges the authorization code for tokens, enforces tenant isolation, and issues the session cookie.

## Requirements

### State JWT Validation

The `state` query parameter is validated as a JWT signed with `STATE_JWT_SECRET` (HS256) before processing any callback. If the JWT is malformed, has an invalid signature, or is expired, the service responds with HTTP 400 and renders `error.html`.

### Authorization Code Exchange

The `code` query parameter is exchanged for tokens by POSTing to `https://<COGNITO_DOMAIN>/oauth2/token` with `grant_type=authorization_code` and HTTP Basic authentication using the tenant's App Client credentials. If the Cognito token endpoint returns a non-200 response, the service responds with HTTP 400 and renders `error.html`.

### Tenant Isolation Enforcement

The email domain is extracted from the `id_token`, the Discovery Service is queried, and the returned `tenant_id` is compared with the `tenant_id` in the state JWT. If they differ, the service responds with HTTP 403 and renders `error.html`.

### Session Cookie Issuance

On success (valid state, successful token exchange, matching tenant IDs), the service sets a `session` cookie containing the Cognito `id_token` with these attributes:
- `HttpOnly`
- `Secure`
- `SameSite=Lax`
- `Domain=.wasp.silvios.me`

The response is HTTP 302 redirecting to the `return_url` from the state JWT.

### Per-Tenant Client Secret Lookup

Each tenant's Cognito App Client secret is resolved from an environment variable named `COGNITO_CLIENT_SECRET_<TENANT_ID_UPPERCASE>`. If the environment variable for the requesting tenant does not exist, the service responds with HTTP 500 and renders `error.html`.

### Health Endpoint

`GET /health` returns HTTP 200 with `{"status": "ok"}` regardless of authentication state.