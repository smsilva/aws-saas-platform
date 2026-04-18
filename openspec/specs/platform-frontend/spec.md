# Platform Frontend

## Purpose

Define the behavioral contracts for the platform login frontend, which acts as the IdP router: it receives the user's email, discovers the correct tenant IdP, and initiates the OAuth 2.0 Authorization Code Flow.

## Requirements

### Requirement: Login Page Rendering

The system SHALL render `login.html` on `GET /` without requiring any authentication.

### Requirement: Email-Based IdP Routing

The system SHALL accept a user's email via `POST /login`, extract the domain portion, query the Discovery Service, and redirect to the Cognito Hosted UI for the corresponding tenant.

#### Scenario: Valid email with registered domain

WHEN a user submits `sarah@customer1.com`
AND `customer1.com` is registered in the Discovery Service
THEN the service SHALL respond with HTTP 302 to `https://<COGNITO_DOMAIN>/oauth2/authorize` with the correct `client_id`, `identity_provider`, `state`, and `redirect_uri`

#### Scenario: Invalid email format

WHEN a user submits an email missing `@` or a dot in the domain
THEN the service SHALL re-render `login.html` with an error message
AND SHALL NOT call the Discovery Service

#### Scenario: Domain not found

WHEN a user submits an email whose domain is not registered in the Discovery Service
THEN the service SHALL re-render `login.html` with an error message

### Requirement: CSRF Protection via State JWT

The system SHALL sign a state JWT (HS256, expiry 10 minutes) containing `tenant_id`, `client_id`, `return_url`, and a random `nonce`, and pass it as the `state` parameter in the Cognito authorization URL.

### Requirement: Cognito Authorization URL Construction

The system SHALL build the Cognito authorization URL with the following parameters:

| Parameter | Value |
|---|---|
| `client_id` | Cognito App Client ID for the tenant |
| `identity_provider` | IdP name from Discovery Service |
| `redirect_uri` | `https://auth.wasp.silvios.me/callback` |
| `response_type` | `code` |
| `scope` | `openid email profile` |
| `state` | Signed state JWT |

### Requirement: Health Endpoint

The system SHALL expose `GET /health` returning HTTP 200 with `{"status": "ok"}`.
