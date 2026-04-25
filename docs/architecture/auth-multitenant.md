# Auth Multitenant

## Purpose

Define the multi-tenant authentication architecture where Cognito acts as a federation hub, normalizing identity tokens from any upstream IdP (Google, Microsoft, Okta, Auth0, Keycloak) into a consistent JWT consumed by the platform.

## Requirements

### Single Normalized JWT Issuer

Cognito always issues JWTs to the platform regardless of which upstream IdP the tenant uses. The platform never receives or validates tokens from upstream IdPs directly.

### Per-Tenant Cognito App Client

One Cognito App Client is created per tenant. Each App Client is linked to exactly one upstream IdP.

### Tenant ID Injection via Pre-Token Lambda

A Cognito Pre-Token Generation Lambda trigger injects `custom:tenant_id` into every JWT. The `tenant_id` is derived from the App Client ID used during authentication and cannot be set by the end user.

**Example:** A user authenticating through App Client `abc123` (belonging to `customer1`) receives a JWT containing `custom:tenant_id = "customer1"`.

### Cross-Tenant Access Prevention

A JWT issued for one tenant cannot access another tenant's resources. When `sarah@customer1.com` presents her valid JWT at `customer2.wasp.silvios.me`, the Istio `AuthorizationPolicy` in namespace `customer2` responds with HTTP 403. The JWT remains valid for `customer1.wasp.silvios.me`.

### Email-Domain-Based IdP Discovery

The platform routes a user to the correct Cognito App Client based solely on the domain portion of their email address, with no manual tenant selection required.

When `motoko@customer2.com` is received and `customer2.com` is registered in `tenant-registry`, the discovery lookup returns the `client_id` and `idp_name` for `customer2`. When the domain is not registered, the lookup returns HTTP 404 and the platform-frontend re-renders the login page with an error message.

### Centralized OAuth Callback URI

A single callback URI `https://auth.wasp.silvios.me/callback` is registered across all IdPs, so new tenants do not require a new redirect URI registration on the platform side.

### Cognito User Pool Limit Awareness

The platform supports up to 300 tenants per Cognito User Pool (AWS hard limit for external IdPs). Beyond that threshold, additional User Pools are provisioned.

### DynamoDB Tenant Registry

Tenant configuration is stored in DynamoDB table `tenant-registry` with primary key `domain#<email-domain>`.

Each item contains: `tenant_id`, `url`, `regions`, `cognito_app_client_id`, and `auth` map with `cognito_idp_name` and `cognito_user_pool_id`.