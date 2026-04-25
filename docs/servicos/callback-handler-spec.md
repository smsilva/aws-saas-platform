# Callback Handler

## Purpose

Define the behavioral contracts for the OAuth 2.0 callback processor. This service is the only component that handles real authentication tokens: it validates the CSRF state, exchanges the authorization code for tokens, enforces tenant isolation, and issues the session cookie.

## Requirements

### Requirement: State JWT Validation

The system SHALL validate the `state` query parameter as a JWT signed with `STATE_JWT_SECRET` (HS256) before processing any callback.

#### Scenario: Invalid or expired state

WHEN the `state` JWT is malformed, has an invalid signature, or is expired
THEN the service SHALL respond with HTTP 400 and render `error.html`

### Requirement: Authorization Code Exchange

The system SHALL exchange the `code` query parameter for tokens by POSTing to `https://<COGNITO_DOMAIN>/oauth2/token` with `grant_type=authorization_code` and HTTP Basic authentication using the tenant's App Client credentials.

#### Scenario: Token exchange fails

WHEN the Cognito token endpoint returns a non-200 response
THEN the service SHALL respond with HTTP 400 and render `error.html`

### Requirement: Tenant Isolation Enforcement

The system SHALL extract the email domain from the `id_token`, query the Discovery Service, and compare the returned `tenant_id` with the `tenant_id` present in the state JWT.

#### Scenario: Tenant ID mismatch

WHEN the `tenant_id` from the Discovery Service differs from the `tenant_id` in the state JWT
THEN the service SHALL respond with HTTP 403 and render `error.html`

### Requirement: Session Cookie Issuance

The system SHALL set a `session` cookie containing the Cognito `id_token` with these attributes:
- `HttpOnly`
- `Secure`
- `SameSite=Lax`
- `Domain=.wasp.silvios.me`

#### Scenario: Successful callback

WHEN state is valid, token exchange succeeds, and tenant IDs match
THEN the service SHALL set the session cookie and redirect with HTTP 302 to the `return_url` from the state JWT

### Requirement: Per-Tenant Client Secret Lookup

The system SHALL resolve each tenant's Cognito App Client secret from an environment variable named `COGNITO_CLIENT_SECRET_<TENANT_ID_UPPERCASE>`.

#### Scenario: Tenant secret not configured

WHEN the environment variable for the requesting tenant does not exist
THEN the service SHALL respond with HTTP 500 and render `error.html`

### Requirement: Health Endpoint

The system SHALL expose `GET /health` returning HTTP 200 with `{"status": "ok"}` regardless of authentication state.
