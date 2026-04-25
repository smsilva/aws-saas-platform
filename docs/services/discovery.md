# Discovery Service

> Given an email domain, returns the corresponding tenant configuration by querying the DynamoDB `tenant-registry` table.

## Responsibility

Single responsibility: map `email domain → TenantConfig`. Called by:

- `platform-frontend` — when the login form is submitted, to discover which IdP to use
- `callback-handler` — to validate that the token's domain belongs to the expected tenant

## API

### `GET /tenant`

Returns the tenant configuration for the given domain.

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `domain` | string (query) | yes | Email domain (e.g. `customer1.com`) |

**Responses:**

=== "200 OK"

    ```json
    {
      "tenant_id": "customer1",
      "tenant_url": "customer1.wasp.silvios.me",
      "client_id": "<cognito-app-client-id>",
      "idp_name": "Google",
      "idp_pool_id": "<pool-id>"
    }
    ```

=== "404 Not Found"

    ```json
    {
      "detail": "Tenant not found for domain: customer1.com"
    }
    ```

### `GET /health`

```json
{"status": "ok"}
```

## TenantConfig model

Defined in `services/discovery/app/models.py`:

| Field | Type | Description |
|---|---|---|
| `tenant_id` | `str` | Unique tenant identifier (e.g. `customer1`) |
| `tenant_url` | `str` | Tenant hostname without scheme (e.g. `customer1.wasp.silvios.me`) |
| `client_id` | `str` | Cognito App Client ID for the tenant |
| `idp_name` | `str` | Name of the IdP configured in Cognito (e.g. `Google`, `MicrosoftAD-Customer2`) |
| `idp_pool_id` | `str` | User Pool ID / IdP Pool ID |

## DynamoDB repository

Implemented in `services/discovery/app/repository.py` (`DynamoDBTenantRepository`).

**Primary key:** `pk = "domain#<domain>"` (lowercase)

DynamoDB attribute to `TenantConfig` mapping:

| DynamoDB attribute | Model field | Notes |
|---|---|---|
| `pk` | — | Lookup key: `domain#customer1.com` |
| `tenant_id` | `tenant_id` | |
| `url` | `tenant_url` | |
| `cognito_app_client_id` | `client_id` | |
| `auth.M.cognito_idp_name` | `idp_name` | Nested attribute in the `auth` map |
| `auth.M.cognito_user_pool_id` | `idp_pool_id` | Nested attribute in the `auth` map |

!!! warning "DynamoDB — reserved words"
    `auth` is a reserved word in DynamoDB. In `--update-expression`, use alias `#auth` with `--expression-attribute-names '{"#auth": "auth"}'`. See [operational gotchas](../operations/README.md#operational-gotchas).

## IRSA

The service uses IRSA to access DynamoDB without hardcoded credentials in the container.

Required permission: `dynamodb:GetItem` on the `tenant-registry` table.

The service account and IAM role are provisioned by script `13-deploy-services`.

## Environment variables

| Variable | Description |
|---|---|
| `AWS_REGION` | AWS region where the DynamoDB table is |
| `DYNAMODB_TABLE` | Table name (default: `tenant-registry`) |

## Kubernetes namespace and deploy

- **Namespace:** `discovery`
- **Image:** `silviosilva/wasp-discovery:<sha>`
- **Service account:** bound to the IAM role via IRSA

## Caching

The repository uses `@lru_cache` at the boto3 client factory level, but **does not cache** individual query results. Each `GET /tenant` call results in a `GetItem` against DynamoDB.

The decision to add in-memory caching (TTL, invalidation) is open. See [technical-decisions.md](../technical-decisions.md).

## Tests

```bash
cd services/discovery
.venv/bin/pytest tests/ -v
```

- `test_tenant_api.py` — tests HTTP endpoints with FastAPI `TestClient`
- `test_tenant_repository.py` — tests `InMemoryTenantRepository` and `DynamoDBTenantRepository` (with mocked boto3 client)

---

## Formal Specification

### Purpose

Define the behavioral contracts for the tenant discovery service, which maps an email domain to the corresponding tenant configuration stored in DynamoDB.

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
