# Platform Frontend

## Purpose

Define the behavioral contracts for the platform login frontend, which acts as the IdP router: it receives the user's email, discovers the correct tenant IdP, and initiates the OAuth 2.0 Authorization Code Flow.

## Requirements

### Login Page Rendering

`GET /` renders `login.html` without requiring any authentication.

### Email-Based IdP Routing

`POST /login` accepts a user's email, extracts the domain portion, queries the Discovery Service, and redirects to the Cognito Hosted UI for the corresponding tenant.

- Valid email with a registered domain (e.g., `sarah@customer1.com`): responds with HTTP 302 to `https://<COGNITO_DOMAIN>/oauth2/authorize` with the correct `client_id`, `identity_provider`, `state`, and `redirect_uri`.
- Invalid email format (missing `@` or dot in domain): re-renders `login.html` with an error message without calling the Discovery Service.
- Domain not found in Discovery Service: re-renders `login.html` with an error message.

### CSRF Protection via State JWT

A state JWT (HS256, expiry 10 minutes) containing `tenant_id`, `client_id`, `return_url`, and a random `nonce` is signed and passed as the `state` parameter in the Cognito authorization URL.

### Cognito Authorization URL Construction

The Cognito authorization URL is built with the following parameters:

| Parameter | Value |
|---|---|
| `client_id` | Cognito App Client ID for the tenant |
| `identity_provider` | IdP name from Discovery Service |
| `redirect_uri` | `https://auth.wasp.silvios.me/callback` |
| `response_type` | `code` |
| `scope` | `openid email profile` |
| `state` | Signed state JWT |

### Health Endpoint

`GET /health` returns HTTP 200 with `{"status": "ok"}`.