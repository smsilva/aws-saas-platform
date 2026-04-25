# Technical decisions — backlog and trade-offs

Record of design decisions made during lab development, with the reasoning behind each choice and what was consciously deferred.

---

## External references

Articles that informed the architecture of this lab:

- [Building a Multi-Tenant SaaS Solution Using Amazon EKS](https://aws.amazon.com/pt/blogs/apn/building-a-multi-tenant-saas-solution-using-amazon-eks/) — Toby Buckley and Ranjith Raman (AWS APN Blog)
- [Operating a multi-regional stateless application using Amazon EKS](https://aws.amazon.com/pt/blogs/containers/operating-a-multi-regional-stateless-application-using-amazon-eks/) — Re Alvarez-Parmar (AWS Containers Blog)
- [Amazon EKS Blueprints for Terraform](https://aws-ia.github.io/terraform-aws-eks-blueprints/) — reference Terraform modules for EKS

---

## Phase roadmap and waspctl

**Status:** Phase 1 in progress; Phases 2 and 3 planned

This lab manually implements Phase 1 infrastructure. In parallel, the [`waspctl`](https://github.com/smsilva/waspctl) project is being developed as a CLI to automate provisioning of this same topology.

| Phase | Description | State |
|---|---|---|
| 1 | Single cluster + simple Auth Service (this lab) | in progress |
| 2 | Platform-cluster separate from customer-clusters | planned |
| 3 | Regional platform-clusters + Global Accelerator + DynamoDB Global Table | planned |

`waspctl` will follow the same phase progression, abstracting manual scripts into declarative commands:

```bash
waspctl sso login

waspctl instance list

NAME     DOMAIN            REGIONS               OWNER

waspctl instance create \
  --name wasp-x3b5 \
  --region us-east-1 \
  --region eu-north-1 \
  --domain wasp.silvios.me

waspctl instance list

NAME      DOMAIN            REGIONS               OWNER
wasp-x3b5  wasp.silvios.me  us-east-1,eu-north-1  administrators

waspctl instance create \
  --name wasp-i4dy \
  --region us-east-1 \
  --domain dev.wasp.silvios.me

waspctl instance list

NAME       DOMAIN               REGIONS               OWNER
wasp-x3b5  wasp.silvios.me      us-east-1,eu-north-1  administrators
wasp-i4dy  dev.wasp.silvios.me  us-east-1             administrators

waspctl customer create \
  --name customer1-us-east-1 \
  --instance wasp-x3b5 \
  --region us-east-1

waspctl tenant create \
  --name customer1 \
  --domain customer1.com \
  --gateway customer1-us-east-1-xt56.wasp.silvios.me

waspctl tenant endpoint add \
  --tenant customer1.com \
  --endpoint customer1-eu-north-1-yh98.wasp.silvios.me
```

---

## ALB native Cognito integration vs custom Auth Service

**Status:** decision made; custom Auth Service retained for flexibility

### Context

The ALB has native Cognito integration: the ALB itself executes the OIDC/OAuth flow and injects JWT claims as HTTP headers before forwarding the request to the backend. This would eliminate the need for `platform-frontend` and `callback-handler` as separate services.

### Options evaluated

**A — ALB native Cognito (OIDC authenticate action)**
The ALB redirects to the Cognito Hosted UI, exchanges the authorization code for a token, and injects `X-Amzn-Oidc-Identity`, `X-Amzn-Oidc-Access-Token`, and `X-Amzn-Oidc-Data` (JWT with claims) into headers. Zero authentication code in the backend.

**B — Custom Auth Service (current solution)**
`platform-frontend` receives the email, resolves the tenant via discovery, builds the authorization URL for the correct Cognito IdP, and redirects. `callback-handler` receives the code, exchanges it for a token, validates the tenant, and sets the session cookie.

### Decision: Custom Auth Service (Option B)

The ALB native integration does not offer control over dynamic per-tenant IdP selection — the ALB authenticates against a single fixed Cognito App Client in the listener rule. The custom Auth Service allows:

- Resolving the tenant by email domain **before** initiating the OAuth flow
- Building the authorization URL with the correct `identity_provider` for the tenant
- Validating that the authenticated domain belongs to the expected tenant (anti-hijacking protection)
- Injecting tenant information into the state JWT for correlation in the callback

The ALB native integration is appropriate for cases where all users authenticate through the same IdP. For multi-tenant with distinct IdPs per tenant, the custom Auth Service is necessary.

---

## API auth options for external clients

**Status:** pending decision

How to authenticate `curl`/script calls to the API without going through the browser SSO flow.

### Options evaluated

**A — Service account token (Kubernetes Secret)**
Create a dedicated `ServiceAccount` with limited permissions and use the automatically generated token. Simple, no AWS dependency, but long-lived token (no expiration by default before Kubernetes 1.24).

**B — AWS SigV4 (IAM)**
Sign requests with IAM credentials via `aws-sigv4`. Requires the API Gateway or proxy to validate the signature. Integrates well with IRSA for workloads in the cluster, but adds client complexity.

**C — Cognito client credentials flow (OAuth 2.0 machine-to-machine)**
Create a Cognito App Client without a user, use `grant_type=client_credentials` to obtain an access token. Short-lived token, auditable, no browser. Standard for M2M in OAuth 2.0.

**Decision:** Option C evaluated as most aligned with the OAuth 2.0 M2M standard. Implementation deferred — no option chosen yet.

---

## Per-tenant secrets in the callback-handler

**Status:** temporary solution in production in the lab; optimal solution documented and deferred

### Problem

The `callback-handler` needs each Cognito App Client's `client_secret` to exchange the authorization code for a token. With multiple tenants, each has its own App Client with a different secret.

### Current solution (lab)

Env vars named by convention: `COGNITO_CLIENT_SECRET_<TENANT_ID_UPPERCASE>`.
Injected via Kubernetes Secret created/updated by the deploy script.

```python
tenant_key = login_state.tenant_id.upper()   # "customer1" → "CUSTOMER1"
client_secret = os.environ[f"COGNITO_CLIENT_SECRET_{tenant_key}"]
```

Kubernetes Secret with one key per tenant:

```yaml
stringData:
  COGNITO_CLIENT_SECRET_CUSTOMER1: "<secret1>"
  COGNITO_CLIENT_SECRET_CUSTOMER2: "<secret2>"
  STATE_JWT_SECRET: "<jwt-secret>"
```

**Limitation:** adding a tenant requires editing the Secret + rollout of callback-handler. Secrets in base64 in etcd without encryption at rest by default.

### Optimal solution for production (deferred)

**External Secrets Operator + AWS Secrets Manager**

- ESO automatically syncs Secrets Manager → K8s Secret
- Rotation managed by AWS
- Adding a tenant = create secret in Secrets Manager, no deployment changes
- De facto standard for EKS in production with this stack (ESO + ArgoCD)

**Alternative — SDK call at runtime:**
The callback-handler calls Secrets Manager directly using `tenant_id` as the key. Zero redeployment when adding a tenant. Downside: extra latency on the critical login path.

**When to revisit:** when scaling beyond ~5 tenants or when moving to production.

---

## Discovery service caching

**Status:** deferred; no cache today

### Context

The discovery service is called **twice per login**: once by `platform-frontend` (when the email is submitted) and once by `callback-handler` (to validate that the authenticated email domain belongs to the expected tenant). Each call queries DynamoDB. Outside the login flow, Istio validates the JWT directly via JWKS — discovery is not involved.

For typical login volumes, DynamoDB latency is acceptable. The real risk is **availability**: if DynamoDB or the discovery service becomes unavailable, login fails.

### Options evaluated

**A — In-memory cache with TTL in the process (recommended)**
Dict with timestamp per domain. Domain not found or expired goes to DynamoDB. A 5-minute TTL eliminates almost all calls (domains change rarely). Zero additional infrastructure.

**B — ElastiCache (Redis/Memcached)**
Cache shared across pods and regions. Useful if the number of discovery pods grows significantly. Adds infrastructure, cost, and operational complexity — not justified at the current stage.

**C — DynamoDB DAX**
Managed cache in front of DynamoDB, microsecond latency. High cost for this access pattern (logins, not continuous queries). Not justified.

### Decision

Option A evaluated as sufficient for the expected volume. Implementation deferred until DynamoDB latency proves to be a real problem in production.

### When to revisit

When observing p99 login latency above 500 ms, or when scaling the number of discovery pods (where per-pod in-memory cache becomes inefficient).

---

## Single shared User Pool vs one per tier/region

**Status:** pending decision

### Context

The Cognito User Pool is a single global instance in the current lab (`us-east-1`). In a multi-region topology with Global Accelerator, the callback can return to any regional cluster — all need to validate JWTs issued by the same pool.

### Options

**A — Single global User Pool**
Simple; all clusters validate the same JWKS. Validation latency depends on the Cognito JWKS endpoint (generally low, with caching). Limit of 300 external IdPs per pool.

**B — One User Pool per region (aligned with Global Accelerator)**
Each region has its own pool; the frontend uses the pool from the nearest region. Eliminates cross-region dependency in the authentication path. Adds complexity: the `client_id` per tenant must be replicated per region, and the callback needs to know which pool to redirect to.

### When to decide

When planning multi-region expansion. For the single-cluster lab, a single User Pool is sufficient.

---

## Keycloak self-hosted — SLA coupled to customer risk

**Status:** risk documented; decision to accept or mitigate pending a real case

### Context

When a tenant uses self-hosted Keycloak, Cognito needs network connectivity to the customer's Keycloak server during login. If the customer's Keycloak becomes unavailable, the entire tenant's login breaks.

### Mitigation options

| Option | Trade-off |
|---|---|
| Customer exposes Keycloak publicly with TLS | Simpler; exposes customer infrastructure |
| AWS PrivateLink + site-to-site VPN | More secure; high operational complexity |
| Customer migrates to Keycloak Cloud (managed) | Eliminates the problem; depends on the customer's decision |
| Document as explicit contractual risk | Zero technical cost; platform SLA degraded for that tenant |

### Recommended decision

Document as explicit contractual risk for any tenant with self-hosted Keycloak. Require a Keycloak availability SLA as a prerequisite for onboarding, or offer a differentiated tier.

---

## Cross-region session — stateless JWT tokens

**Status:** decision made for access tokens; refresh tokens require attention

### Context

With Global Accelerator across multiple regional clusters, a user can start login in `us-east-1` and have the callback processed in `eu-central-1`. The Cognito JWT is stateless — any cluster with access to the Cognito JWKS can validate it.

### Decision

JWT access tokens work without shared state between regions. Each cluster validates the JWT locally against the Cognito JWKS (with local cache).

Refresh tokens issued by Cognito are opaque and need to be exchanged at the same User Pool that issued them — Cognito handles this globally. If the platform stores refresh tokens in DynamoDB for transparent renewal, the table must be a **DynamoDB Global Table** for local access in any region.

---

## Microsoft MSA vs corporate Azure AD in Cognito

**Status:** decision made

### Context

Cognito supports two types of issuer for Microsoft accounts, and the distinction must be made before creating the IdP:

| Account type | `oidc_issuer` | When to use |
|---|---|---|
| Microsoft personal accounts (MSA, Hotmail, Outlook.com) | `https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0` | Fixed GUID for MSA — not a real tenant ID |
| Corporate Azure AD / Google Workspace federated via Azure AD | `https://login.microsoftonline.com/<azure-tenant-id>/v2.0` | Use the organization's real tenant ID in Azure |

### Decision

Register the IdP in Cognito with the `oidc_issuer` corresponding to the account type. The most common mistake is using the MSA GUID for corporate accounts (or vice versa), resulting in silent authentication failures.

For corporate SaaS tenants, the expected case is **Azure AD with a real tenant ID**. MSA is relevant only if the platform accepts Microsoft personal accounts.

---

## Gateway API vs classic Ingress in ALB Controller

**Status:** decision made; revisit when the ALB Controller v3.x series stabilizes

### Context

AWS Load Balancer Controller v3.x added support for the Kubernetes Gateway API (`GatewayClass`, `Gateway`, `HTTPRoute`) starting with v3.0. This lab intentionally uses the classic `Ingress` and `IngressClass` resources.

### Decision: keep Ingress/IngressClass

Issue [kubernetes-sigs/aws-load-balancer-controller#4674](https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/4674) (opened in April 2026) reports that upgrading from `v3.1.0` to `v3.2.1` breaks installations where the Gateway API is **not enabled**, because the `ListenerSet` CRDs are absent. While this type of compatibility issue is not stabilized, keeping `Ingress`/`IngressClass` is the conservative choice.

The Istio `Gateway` + `VirtualService` (step 08) is an Istio resource and is **not** affected by this ALB Controller limitation.

### When to revisit

- Resolution of issue #4674 and other compatibility bugs in the v3.x series
- Evaluate `HTTPRoute` → ALB to replace the current `Ingress` (`07-configure-alb-ingress`)

---

## Per-tenant DNS — CNAME vs Global Accelerator

**Status:** decision made; waspctl implementation planned for Phase 3

### Context

The apex `wasp.silvios.me` requires Global Accelerator because CNAME-at-apex is prohibited by RFC 1034 and Azure DNS does not support ALIAS records for external ALBs. Subdomains like `customer1.wasp.silvios.me` have no such restriction — a direct CNAME to the ALB hostname works normally.

Global Accelerator was tested in the lab for the apex. The question is how to handle tenant subdomains that need regional failover (e.g., `customer1.wasp.silvios.me` → `us-east-1` with failover to `eu-west-1`) without creating one accelerator per tenant.

### Options evaluated

**A — One Global Accelerator per tenant with failover**
Each premium tenant has its own static anycast IPs. Allows completely independent failover configuration (target region, health check threshold). Cost: ~$18/month per accelerator. Default limit: 20 accelerators per AWS account.

**B — Shared Global Accelerator per failover profile**
Tenants that need the same region pair (e.g., `us-east-1 → eu-west-1`) share a single accelerator. Per-tenant routing happens at the host header (ALB → Istio VirtualService) — the anycast IPs are the same for everyone in the group. Cost split across N tenants in the same profile.

**C — Direct CNAME (no failover)**
For tenants without failover requirements, CNAME to the ALB hostname. Zero additional infrastructure cost. No static IPs, but that is not a problem for subdomains.

### Decision: two-tier model

| Tier | DNS | Infrastructure | Failover |
|---|---|---|---|
| Standard | `CNAME → alb-hostname.amazonaws.com` | none | none |
| Premium | `A record → shared GA IPs` | GA per region pair | simultaneous regional for all in the GA |

A dedicated GA per tenant (Option A) is only justified when the tenant requires **different failover configuration** from others in the same region pair — e.g., different threshold, exclusive target region, or an SLA requiring total isolation.

### Data model for waspctl

The `failover_tier` field in the tenant record determines DNS behavior:

```json
{
  "tenant_id": "customer1",
  "failover_tier": "us-east-1-to-eu-west-1",
  "dns_type": "accelerator"
}
```

```json
{
  "tenant_id": "customer2",
  "failover_tier": null,
  "dns_type": "cname"
}
```

`waspctl tenant create` would consult `failover_tier` to decide whether to:
1. Create a new GA (first tenant for that region pair)
2. Reuse an existing GA (additional tenants on the same pair)
3. Create only a CNAME (tenants without failover)

### Shared GA limitation

The failover trigger (health check on the endpoint group) is **shared** — if the `us-east-1` ALB fails, all tenants in the same GA fail over simultaneously. This behavior is acceptable when the failover cause is shared infrastructure (the ALB/cluster itself). If tenants need independent failover for SLA reasons or contained blast radius, a dedicated GA is required.

---

## STATE_JWT_SECRET in multi-region deployments

**Status:** decision made; rotation implementation deferred

### Context

`STATE_JWT_SECRET` is the shared secret between `platform-frontend` and `callback-handler` for signing and verifying the OAuth flow state JWT (CSRF protection). Cognito is a single global instance — the callback returns to `auth.wasp.silvios.me`, which Global Accelerator can route to **any** regional cluster.

### Decision: identical secret in all clusters

If the state JWT was signed in `us-east-1` but the callback lands in `eu-central-1`, the `callback-handler` in that region needs to verify the signature. Therefore `STATE_JWT_SECRET` must be the same in all regional clusters.

### Implications

- **Provisioning:** the secret must be replicated to all regions. With ESO + Secrets Manager with cross-region replication, this is automatic.
- **Rotation:** must be coordinated — all clusters must receive the new secret simultaneously, or accept two secrets during a transition window (would require support for multiple secrets in `decode_state_token`).
- **Compromise:** if the secret leaks, an attacker can forge valid state JWTs. The short expiration (10 minutes) limits the exploitation window — immediate rotation invalidates all in-flight states (users need to restart login).

### Optimal rotation solution (deferred)

Support for two simultaneous secrets in `decode_state_token` (try verifying with the new one; if it fails, try the previous one). Allows rotation without UX downgrade. Implement alongside the migration to ESO + Secrets Manager.
