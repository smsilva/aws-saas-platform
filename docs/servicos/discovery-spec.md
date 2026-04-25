# Discovery Service

## Purpose

Define the behavioral contracts for the tenant discovery service, which maps an email domain to the corresponding tenant configuration stored in DynamoDB.

## Requirements

### Requirement: Domain-to-Tenant Resolution

The system SHALL resolve an email domain to a `TenantConfig` by looking up the primary key `domain#<domain>` (lowercase) in the DynamoDB table `tenant-registry`.

#### Scenario: Known domain

WHEN `GET /tenant?domain=customer1.com` is called
AND `domain#customer1.com` exists in `tenant-registry`
THEN the service SHALL respond with HTTP 200 and a JSON body containing `tenant_id`, `tenant_url`, `client_id`, `idp_name`, and `idp_pool_id`

#### Scenario: Unknown domain

WHEN `GET /tenant?domain=unknown.com` is called
AND no item with key `domain#unknown.com` exists in `tenant-registry`
THEN the service SHALL respond with HTTP 404 and `{"detail": "Tenant not found for domain: unknown.com"}`

### Requirement: DynamoDB Access via IRSA

The system SHALL access DynamoDB using IRSA (IAM Roles for Service Accounts), requiring only `dynamodb:GetItem` on the `tenant-registry` table. No hardcoded credentials SHALL be present in the container.

### Requirement: TenantConfig Response Schema

The system SHALL return the following fields in every successful response:

| Field | Type | Source attribute |
|---|---|---|
| `tenant_id` | string | `tenant_id` |
| `tenant_url` | string | `url` |
| `client_id` | string | `cognito_app_client_id` |
| `idp_name` | string | `auth.cognito_idp_name` |
| `idp_pool_id` | string | `auth.cognito_user_pool_id` |

### Requirement: Health Endpoint

The system SHALL expose `GET /health` returning HTTP 200 with `{"status": "ok"}`.

### Requirement: No Result Caching

The system SHALL NOT cache DynamoDB query results. Each call to `GET /tenant` SHALL perform a `GetItem` against DynamoDB.
