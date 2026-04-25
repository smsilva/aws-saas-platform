# Modules

Each module in `src/` is self-contained — no hard-coded values, all configuration via variables.

## vpc

**Path:** `src/vpc`

Provisions a VPC with public and private subnets distributed across availability zones.

| Input | Type | Description |
|---|---|---|
| `name` | `string` | Name prefix for all resources |
| `cidr` | `string` | VPC CIDR block |
| `subnets` | `list(object)` | List of subnets — each with `cidr`, `name`, `availability_zone`, `public` |
| `tags` | `map(string)` | Resource tags |

| Output | Description |
|---|---|
| `id` | VPC ID |
| `public_subnet_ids` | IDs of public subnets |
| `private_subnet_ids` | IDs of private subnets |

---

## eks

**Path:** `src/eks`

Provisions an EKS cluster with a managed node group, default addons, and access entries.

Default addons: `vpc-cni`, `kube-proxy`, `coredns`, `metrics-server` (all pinned to `most_recent`).

| Input | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Cluster name |
| `cluster_version` | `string` | `"1.32"` | Kubernetes version |
| `vpc_id` | `string` | — | VPC where the cluster is created |
| `subnet_ids` | `list(string)` | — | Subnets for the EKS control plane |
| `private_subnet_ids` | `list(string)` | — | Private subnets for the managed node group |
| `node_instance_type` | `string` | `"t3.medium"` | EC2 instance type |
| `node_min_count` | `number` | `1` | Node group minimum size |
| `node_max_count` | `number` | `3` | Node group maximum size |
| `node_desired_count` | `number` | `2` | Node group desired size |
| `access_entries` | `any` | `{}` | Map of IAM principal ARN → policy associations |
| `tags` | `map(string)` | `{}` | Resource tags |

| Output | Description |
|---|---|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Kubernetes API endpoint |
| `oidc_provider_arn` | OIDC provider ARN (used for IRSA) |

---

## dynamodb

**Path:** `src/dynamodb`

Provisions a DynamoDB table with optional global secondary indexes and seed data.

| Input | Type | Description |
|---|---|---|
| `table_name` | `string` | Table name |
| `hash_key` | `string` | Partition key attribute name |
| `attributes` | `list(object)` | Attribute definitions (`name` + `type`: S, N, or B) |
| `global_secondary_indexes` | `list(object)` | GSI list (name, hash_key, projection_type, capacities) |
| `read_capacity` | `number` | Provisioned read capacity (default `5`) |
| `write_capacity` | `number` | Provisioned write capacity (default `5`) |
| `seed_items` | `list(object)` | Initial items in DynamoDB JSON format |
| `tags` | `map(string)` | Resource tags |

| Output | Description |
|---|---|
| `id` | Table name |
| `arn` | Table ARN |

---

## cognito

**Path:** `src/cognito`

Provisions the shared Cognito infrastructure: an IAM role and a Lambda function used as the pre-token-generation trigger across all tenant user pools.

| Input | Type | Description |
|---|---|---|
| `name` | `string` | Name prefix |
| `dynamodb_table_name` | `string` | Passed to Lambda as `DYNAMODB_TABLE` env var |
| `dynamodb_table_arn` | `string` | Used to build the IAM policy (including GSI access) |
| `tags` | `map(string)` | Resource tags |

| Output | Description |
|---|---|
| `lambda_arn` | ARN of the pre-token generation Lambda — pass to each `cognito/userpool` instance |

---

## cognito/userpool

**Path:** `src/cognito/userpool`

Provisions a per-tenant Cognito User Pool with an app client and an external identity provider (Google or Microsoft).

| Input | Type | Default | Description |
|---|---|---|---|
| `tenant` | `string` | — | Tenant name (e.g. `customer1`) |
| `name` | `string` | — | Platform name prefix (e.g. `wasp`) |
| `domain` | `string` | `"wasp.silvios.me"` | Base domain for callback and logout URLs |
| `lambda_arn` | `string` | — | ARN from `module.cognito.lambda_arn` |
| `idp_type` | `string` | `""` | IdP type: `"google"`, `"microsoft"`, or `""` to skip |
| `idp_client_id` | `string` | `""` | OAuth client ID |
| `idp_client_secret` | `string` | `""` | OAuth client secret (sensitive) |
| `callback_urls` | `list(string)` | `[]` | Defaults to `https://auth.<domain>/callback` |
| `logout_urls` | `list(string)` | `[]` | Defaults to `https://<tenant>.<domain>/logout` |
| `tags` | `map(string)` | `{}` | Resource tags |

| Output | Description |
|---|---|
| `user_pool_id` | Cognito User Pool ID |
| `user_pool_arn` | Cognito User Pool ARN |
| `app_client_id` | App Client ID for this tenant |
| `app_client_secret` | App Client secret (sensitive) |

---

## waf

**Path:** `src/waf`

Provisions a WAFv2 regional web ACL. The `alb_arn` input is optional — omit it to create the ACL without associating it to a load balancer.

| Input | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name prefix |
| `alb_arn` | `string` | `""` | ALB ARN to associate with the web ACL |
| `tags` | `map(string)` | `{}` | Resource tags |

| Output | Description |
|---|---|
| `id` | Web ACL ID |
| `arn` | Web ACL ARN |
