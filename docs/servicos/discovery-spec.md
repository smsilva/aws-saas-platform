# Discovery Service

## Purpose

Define the behavioral contracts for the tenant discovery service, which maps an email domain to the corresponding tenant configuration stored in DynamoDB.

## Requirements

### Domain-to-Tenant Resolution

Resolves an email domain to a `TenantConfig` by looking up the primary key `domain#<domain>` (lowercase) in the DynamoDB table `tenant-registry`.

`GET /tenant?domain=customer1.com` returns HTTP 200 with a JSON body containing `tenant_id`, `tenant_url`, `client_id`, `idp_name`, and `idp_pool_id` when the domain is registered. When no item exists for the domain, the service responds with HTTP 404 and `{"detail": "Tenant not found for domain: unknown.com"}`.

### DynamoDB Access via IRSA

DynamoDB is accessed via IRSA (IAM Roles for Service Accounts), requiring only `dynamodb:GetItem` on the `tenant-registry` table. No hardcoded credentials are present in the container.

### TenantConfig Response Schema

Every successful response returns the following fields:

| Field | Type | Source attribute |
|---|---|---|
| `tenant_id` | string | `tenant_id` |
| `tenant_url` | string | `url` |
| `client_id` | string | `cognito_app_client_id` |
| `idp_name` | string | `auth.cognito_idp_name` |
| `idp_pool_id` | string | `auth.cognito_user_pool_id` |

### Health Endpoint

`GET /health` returns HTTP 200 with `{"status": "ok"}`.

### No Result Caching

DynamoDB query results are not cached. Each call to `GET /tenant` performs a `GetItem` against DynamoDB.