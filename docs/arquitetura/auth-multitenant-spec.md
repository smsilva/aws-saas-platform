# Auth Multitenant

## Purpose

Define the multi-tenant authentication architecture where Cognito acts as a federation hub, normalizing identity tokens from any upstream IdP (Google, Microsoft, Okta, Auth0, Keycloak) into a consistent JWT consumed by the platform.

## Requirements

### Requirement: Single Normalized JWT Issuer

The system SHALL always issue Cognito JWTs to the platform, regardless of which upstream IdP the tenant uses. The platform SHALL never receive or validate tokens from upstream IdPs directly.

### Requirement: Per-Tenant Cognito App Client

The system SHALL create one Cognito App Client per tenant. Each App Client SHALL be linked to exactly one upstream IdP.

### Requirement: Tenant ID Injection via Pre-Token Lambda

The system SHALL inject `custom:tenant_id` into every JWT using a Cognito Pre-Token Generation Lambda trigger. The `tenant_id` SHALL be derived from the App Client ID used during authentication and SHALL NOT be settable by the end user.

#### Scenario: Token carries correct tenant_id

WHEN a user authenticates through App Client `abc123` which belongs to `customer1`
THEN the issued JWT SHALL contain `custom:tenant_id = "customer1"`

### Requirement: Cross-Tenant Access Prevention

The system SHALL prevent a JWT issued for one tenant from accessing another tenant's resources.

#### Scenario: Cross-tenant request is blocked

WHEN `sarah@customer1.com` presents her valid JWT at `customer2.wasp.silvios.me`
THEN the Istio `AuthorizationPolicy` in namespace `customer2` SHALL respond with HTTP 403
AND the JWT SHALL remain valid for `customer1.wasp.silvios.me`

### Requirement: Email-Domain-Based IdP Discovery

The system SHALL route a user to the correct Cognito App Client based solely on the domain portion of their email address, with no manual tenant selection required.

#### Scenario: Domain resolves to tenant

WHEN the platform receives `motoko@customer2.com`
AND `customer2.com` is registered in `tenant-registry`
THEN the discovery lookup SHALL return the `client_id` and `idp_name` for `customer2`

#### Scenario: Domain not registered

WHEN the platform receives an email with an unknown domain
THEN the discovery lookup SHALL return HTTP 404
AND the platform-frontend SHALL re-render the login page with an error message

### Requirement: Centralized OAuth Callback URI

The system SHALL use a single callback URI `https://auth.wasp.silvios.me/callback` registered across all IdPs, so that new tenants do not require a new redirect URI registration on the platform side.

### Requirement: Cognito User Pool Limit Awareness

The system SHALL support up to 300 tenants per Cognito User Pool (AWS hard limit for external IdPs). Beyond that threshold, additional User Pools SHALL be provisioned.

### Requirement: DynamoDB Tenant Registry

The system SHALL store tenant configuration in DynamoDB table `tenant-registry` with primary key `domain#<email-domain>`.

Each item SHALL contain: `tenant_id`, `url`, `regions`, `cognito_app_client_id`, and `auth` map with `cognito_idp_name` and `cognito_user_pool_id`.
