# Differences Between the Local Lab and the AWS EKS Lab

The local lab (`local/`) replicates the behavior of the AWS lab (`scripts/`) without cloud dependencies.
The goal is to test service interface and behavior without incurring provisioning costs.

## Component Mapping

| AWS Component | Local Equivalent | Note |
|---|---|---|
| EKS | k3d (3 servers) | Traefik disabled |
| ALB | HAProxy Ingress (NodePort 32080) | No TLS termination at the ingress |
| ACM + TLS | cert-manager (self-signed CA) | Certificates generated locally for `*.wasp.local` |
| Route 53 / Azure DNS | `/etc/hosts` | Manual entries pointing to `127.0.0.1` |
| Cognito User Pool | Keycloak (bitnami/keycloak) | Realm `wasp`, client `wasp-platform` |
| Cognito Lambda Pre-Token Generation | Keycloak Protocol Mapper | `oidc-usermodel-attribute-mapper` → claim `custom:tenant_id` |
| Cognito App Client per tenant | Single client `wasp-platform` | Isolation via `custom:tenant_id`, not via client ID |
| DynamoDB `tenant-registry` | SQLite (stdlib, in-process) | `BACKEND=sqlite`, seed via ConfigMap |
| IRSA (IAM Roles for Service Accounts) | Direct environment variables | No AWS — `KEYCLOAK_CLIENT_SECRET` in env.secrets |
| Google IdP / Microsoft IdP | No external IdP | `idp_name=""` in seed; `identity_provider` omitted from authorization URL |
| Docker Hub push | `k3d image import` | `imagePullPolicy: Never` on all pods |
| WAF, Global Accelerator | Not implemented | Out of scope for the local lab |

## Additional Environment Variables Added to Services

These variables do not exist in the AWS lab (where values are built from fixed Cognito URLs).
When not defined, services maintain the original behavior for compatibility with the AWS lab.

| Service | Variable | Local Value |
|---|---|---|
| `platform-frontend` | `IDP_AUTHORIZE_URL` | `http://idp.wasp.local:32080/realms/wasp/protocol/openid-connect/auth` |
| `callback-handler` | `IDP_TOKEN_URL` | `http://keycloak.keycloak.svc.cluster.local:8080/realms/wasp/protocol/openid-connect/token` |
| `discovery` | `BACKEND` | `sqlite` |
| `discovery` | `SQLITE_SEED_FILE` | `/seed/tenants.json` (mounted from ConfigMap `discovery-seed`) |

## Traffic Flow

```
Browser (localhost)
  → HAProxy NodePort :32080
  → k3d loadbalancer :32080
  → HAProxy pod
  → Istio IngressGateway (ClusterIP)
  → VirtualService
  → Application (namespace with sidecar injection)
```

In AWS, the ALB performs TLS termination and forwards HTTP to the Istio IngressGateway. Locally, HAProxy receives HTTP directly and forwards to Istio — no TLS on the external path.

## JWT Issuer

Keycloak determines the `iss` field of the JWT based on the realm's `frontendUrl`. Script `05-deploy-keycloak` sets:

```
frontendUrl = http://idp.wasp.local:32080
```

So the issuer in tokens is:

```
http://idp.wasp.local:32080/realms/wasp
```

The Istio `RequestAuthentication` uses this exact value. The `jwksUri` points to the in-cluster service to avoid a round-trip through HAProxy:

```
http://keycloak.keycloak.svc.cluster.local:8080/realms/wasp/protocol/openid-connect/certs
```

## Local vs AWS Multi-tenancy

In AWS, each tenant has a separate Cognito App Client with its own `client_secret`. Locally, all tenants use the same Keycloak client (`wasp-platform`) and therefore the same `client_secret`. Isolation is still enforced by the `custom:tenant_id` claim in the JWT and by Istio `AuthorizationPolicy` — which is the relevant security mechanism.

## Script Sequence

```
bootstrap              # validates dependencies and /etc/hosts
01-create-cluster      # k3d with 3 servers
02-install-haproxy-ingress
03-install-cert-manager
04-install-istio
05-deploy-keycloak     # wasp realm + test users + saves KEYCLOAK_CLIENT_SECRET
06-deploy-services     # discovery, platform-frontend, callback-handler, customer1
07-configure-istio-auth
08-deploy-customer2
destroy                # k3d cluster delete (removes everything)
```

## /etc/hosts Requirements

```
127.0.0.1  wasp.local
127.0.0.1  auth.wasp.local
127.0.0.1  discovery.wasp.local
127.0.0.1  idp.wasp.local
127.0.0.1  customer1.wasp.local
127.0.0.1  customer2.wasp.local
```
