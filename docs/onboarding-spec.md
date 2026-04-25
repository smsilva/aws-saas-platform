# Tenant Onboarding

## Purpose

Define the process and behavioral contracts for registering a new tenant on the platform, covering IdP configuration in Cognito, domain registration in DynamoDB, callback-handler secret update, and Kubernetes namespace provisioning.

## Requirements

### Requirement: IdP Registration in Cognito

The system SHALL support creating a new OIDC identity provider in Cognito for a tenant, with the following required inputs: `client_id`, `client_secret`, `oidc_issuer`, and a unique `idp_name` scoped to the tenant (e.g. `Google-Customer3`).

### Requirement: Per-Tenant App Client

The system SHALL create one Cognito App Client per tenant with:
- Authorization code flow enabled
- `openid email profile` scopes
- Callback URL: `https://auth.<domain>/callback`
- Logout URL: `https://<tenant_id>.<domain>/logout`
- A generated client secret

### Requirement: Domain Registration in DynamoDB

The system SHALL register each tenant email domain in `tenant-registry` as a separate item with primary key `domain#<email-domain>`.

#### Scenario: Domain lookup succeeds after registration

WHEN a domain is registered in `tenant-registry`
THEN `GET /tenant?domain=<domain>` on the Discovery Service SHALL return HTTP 200 with `tenant_id`, `tenant_url`, `client_id`, `idp_name`, and `idp_pool_id`

### Requirement: Callback Handler Secret Update

The system SHALL add the new tenant's Cognito App Client secret to the `callback-handler-secret` Kubernetes Secret and restart the `callback-handler` deployment before traffic is sent to the new tenant.

### Requirement: Isolated Tenant Namespace

The system SHALL create a dedicated Kubernetes namespace per tenant with:
- `istio-injection: enabled` label
- `RequestAuthentication` configured with the Cognito JWKS URI
- `AuthorizationPolicy` that only permits JWTs where `custom:tenant_id` equals the tenant's ID

#### Scenario: Unauthenticated request to tenant namespace

WHEN a request reaches a tenant namespace with no `session` cookie
THEN the response SHALL be HTTP 403

#### Scenario: Wrong-tenant JWT is rejected

WHEN a request carries a JWT with `custom:tenant_id = "customer1"` and targets namespace `customer2`
THEN the response SHALL be HTTP 403

### Requirement: Shared IdP Reuse

WHEN two email domains belong to the same corporate identity directory (same Cognito App Client ID)
THEN the system SHALL allow registering additional domains in `tenant-registry` pointing to the existing App Client
AND SHALL NOT require creating a new IdP or App Client in Cognito

### Requirement: Onboarding Verification

After completing all steps, the system SHALL pass the following checks:
- `GET /tenant?domain=<domain>` → HTTP 200
- Request with no JWT to `<tenant>.wasp.silvios.me` → HTTP 403
- Request with JWT from a different tenant → HTTP 403
- Full browser login flow → lands on `<tenant_id>.<domain>`
