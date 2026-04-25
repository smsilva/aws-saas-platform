# Tenant Onboarding

## Purpose

Define the process and behavioral contracts for registering a new tenant on the platform, covering IdP configuration in Cognito, domain registration in DynamoDB, callback-handler secret update, and Kubernetes namespace provisioning.

## Requirements

### IdP Registration in Cognito

A new OIDC identity provider is created in Cognito for each tenant, with these required inputs: `client_id`, `client_secret`, `oidc_issuer`, and a unique `idp_name` scoped to the tenant (e.g. `Google-Customer3`).

### Per-Tenant App Client

One Cognito App Client is created per tenant with:
- Authorization code flow enabled
- `openid email profile` scopes
- Callback URL: `https://auth.<domain>/callback`
- Logout URL: `https://<tenant_id>.<domain>/logout`
- A generated client secret

### Domain Registration in DynamoDB

Each tenant email domain is registered in `tenant-registry` as a separate item with primary key `domain#<email-domain>`. After registration, `GET /tenant?domain=<domain>` on the Discovery Service returns HTTP 200 with `tenant_id`, `tenant_url`, `client_id`, `idp_name`, and `idp_pool_id`.

### Callback Handler Secret Update

The new tenant's Cognito App Client secret is added to the `callback-handler-secret` Kubernetes Secret and the `callback-handler` deployment is restarted before traffic is sent to the new tenant.

### Isolated Tenant Namespace

A dedicated Kubernetes namespace is created per tenant with:
- `istio-injection: enabled` label
- `RequestAuthentication` configured with the Cognito JWKS URI
- `AuthorizationPolicy` that only permits JWTs where `custom:tenant_id` equals the tenant's ID

Requests with no `session` cookie return HTTP 403. Requests carrying a JWT for a different tenant (e.g., `custom:tenant_id = "customer1"` targeting namespace `customer2`) also return HTTP 403.

### Shared IdP Reuse

When two email domains belong to the same corporate identity directory (same Cognito App Client ID), additional domains can be registered in `tenant-registry` pointing to the existing App Client. No new IdP or App Client in Cognito is required.

### Onboarding Verification

After completing all steps, the following checks must pass:
- `GET /tenant?domain=<domain>` → HTTP 200
- Request with no JWT to `<tenant>.wasp.silvios.me` → HTTP 403
- Request with JWT from a different tenant → HTTP 403
- Full browser login flow → lands on `<tenant_id>.<domain>`