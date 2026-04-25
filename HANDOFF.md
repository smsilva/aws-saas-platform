# HANDOFF — aws-saas-platform

## Current State (2026-04-22)

**AWS resources:** all destroyed. Clean state.
**Active branch:** `dev`

---

## Terraform — implemented modules

All modules in `terraform/src/` are complete and validated (`terraform validate` ✅).

| Module | Resources created |
|---|---|
| `src/vpc` | VPC, subnets (named), IGW, NAT GW, route tables, EKS subnet tags |
| `src/eks` | EKS cluster (via `terraform-aws-modules/eks ~> 21.18`), managed node group, OIDC, Pod Identity (vpc-cni) |
| `src/dynamodb` | DynamoDB PROVISIONED, GSI, seed items |
| `src/cognito` | Lambda pre-token-generation (shared) + IAM |
| `src/cognito/userpool` | User Pool per tenant, IdP (Google/Microsoft), App Client |
| `src/waf` | WAFv2 REGIONAL, 3 managed rules, optional ALB association |

**Example:** `terraform/examples/lab/` — complete lab instance (VPC + EKS + DynamoDB + Cognito + WAF).  
**Backend S3:** bucket `silvios-wasp-foundation` (us-west-2), key `terraform/aws-saas-platform/wasp.tfstate`.

### Gaps Fixed (2026-04-22 session — bash vs Terraform comparison)

Script `scripts/capture-metadata` created to capture real EKS cluster metadata (JSON per resource in `docs/metadata-<source>/`). Full diff in `docs/metadata-diff.md`.

| Gap | Fix | Commit |
|---|---|---|
| Disk: default AMI ~20GB gp2 vs 80GB gp3 | `block_device_mappings` (gp3, 80GB, IOPS 3000, throughput 125) | `8acb8fc` |
| Missing SSO admin role as access entry | `access_entries` variable in module; SSO role in `examples/lab/main.tf` | `b967e2c` |
| Missing `metrics-server` addon | Added to `var.addons` default | `3de012c` |
| `maxUnavailablePercentage=33` (0 slots with 2 nodes) | `update_config { max_unavailable = 1 }` (absolute) | `3de012c` |
| vpc-cni without Pod Identity | IAM role + `pod_identity_association`; `eks-pod-identity-agent` addon | `b5249b3` |

**Deliberately deferred gap:** `node_min_count = 1` (bash uses 2) — kept to save cost in the lab.

### Important Gotchas (don't repeat these mistakes)

- **`terraform-aws-modules/eks` v21 uses `name`, `kubernetes_version`, `endpoint_public_access`** — not `cluster_name`, `cluster_version`, `cluster_endpoint_public_access`
- **`depends_on = [module.vpc]` in the EKS module causes "count depends on unknown values"** — remove it; dependency already implied by arguments `vpc_id`/`subnet_ids`
- **`bootstrap_self_managed_addons = false`** (hardcoded in module v21) — without the `addons` variable defined, AWS does not install vpc-cni/kube-proxy/coredns automatically. Nodes end up in `NetworkUnavailable`.
- **`http_put_response_hop_limit = 1` with IMDSv2 breaks the AL2023 bootstrap** — `nodeadm` cannot reach IMDS. Use `hop_limit = 2`.
- **`attach_cluster_primary_security_group = false` (default)** — nodes cannot reach the EKS private endpoint on port 443. Set to `true`.
- **Cognito `provider_name` for Google must be exactly `"Google"`** — any suffix causes an error when creating the IdP.
- **`global_secondary_index.hash_key` deprecated in provider v6** — use `key_schema { attribute_name, key_type }` block.

---

## Local lab (k3d)

Complete and validated end-to-end in `local/`. Multi-tenant authentication flow with Keycloak working.

**Services modified vs AWS** (all with tests — 114 passing):

| Service | Main change |
|---|---|
| `discovery` | `SQLiteTenantRepository` + `BACKEND=sqlite\|dynamodb` |
| `platform-frontend` | `IDP_AUTHORIZE_URL` optional; `identity_provider` omitted when `idp_name=""` |
| `callback-handler` | `IDP_TOKEN_URL`, `COOKIE_SECURE`, `COOKIE_DOMAIN` configurable |
| `tenant-frontend` | `IDP_LOGOUT_URL`, `LOGOUT_CALLBACK_URL`, `IDP_LOGOUT_REDIRECT_PARAM` configurable; logout with IdP redirect |

**Local gotchas:** see `local/docs/lessons-learned.md`.

---

## Backlog

### P2

- [ ] **Token expiry redirect**: Istio returns a bare 403 — `tenant-frontend` must detect expiry (`exp`) and redirect to `/login`.
- [ ] **Network policy isolating namespaces**: complement Istio isolation with Kubernetes `NetworkPolicy`.
- [ ] **Metrics with OpenTelemetry**: instrument Python services (latency, errors, requests per tenant).
- [ ] **Local e2e testing**: Playwright against k3d covering the full login flow.
- [ ] **Dedicated `/healthz` health check**: separate health check traffic (ALB) from real traffic.

### P3

- [ ] **Cilium CNI in ENI mode**: provision EKS with Cilium instead of AWS VPC CNI.
- [ ] **Istio Ambient Mesh**: implement and verify limitations.
- [ ] **SSM Parameter Store**: migrate secrets from `env.secrets` to SSM.
- [ ] **Resource quotas per namespace**: limit CPU/memory per tenant (noisy neighbor).
- [ ] **CSPM/CIEM/CNAPP**: evaluate Prowler, AWS Security Hub, or a unified solution.
- [ ] **Protect GitHub repository**: branch protection rules, required reviews, signed commits.

---

## References

| Document | Content |
|---|---|
| `docs/metadata-diff.md` | Full diff bash vs Terraform (critical EKS fields) |
| `local/docs/lessons-learned.md` | Gotchas from the local k3d lab |
| `docs/technical-decisions.md` | Design decisions and trade-offs |
| `CLAUDE.md` | Operational context (domains, credentials, TDD rules) |

- [Building a Multi-Tenant SaaS Solution Using Amazon EKS](https://aws.amazon.com/pt/blogs/apn/building-a-multi-tenant-saas-solution-using-amazon-eks)
- [Operating a multi-regional stateless application using Amazon EKS](https://aws.amazon.com/pt/blogs/containers/operating-a-multi-regional-stateless-application-using-amazon-eks)