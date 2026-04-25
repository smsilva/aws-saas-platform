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
    `auth` is a reserved word in DynamoDB. In `--update-expression`, use alias `#auth` with `--expression-attribute-names '{"#auth": "auth"}'`. See [operational gotchas](../operacoes/index.md#operational-gotchas).

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

The decision to add in-memory caching (TTL, invalidation) is open. See [decisoes-tecnicas.md](../decisoes-tecnicas.md).

## Tests

```bash
cd services/discovery
.venv/bin/pytest tests/ -v
```

- `test_tenant_api.py` — tests HTTP endpoints with FastAPI `TestClient`
- `test_tenant_repository.py` — tests `InMemoryTenantRepository` and `DynamoDBTenantRepository` (with mocked boto3 client)
