# Multi-Tenant Authentication Architecture

> **Status:** Under review  
> **Context:** Complements the EKS lab with ALB + Istio Gateway (`README.md`), describing the login flow design for a multi-tenant SaaS platform with support for multiple identity providers (IdP).

---

## Overview

The `wasp.silvios.me` platform serves multiple tenants, each with its own subdomain and, potentially, its own authentication method. The central challenge is: **how to issue a standardized token for the platform regardless of which IdP the tenant uses?**

**Solution:** Cognito as the federation and normalization layer. All authentication passes through Cognito, which federates with the tenant's IdP (Google, Microsoft, Okta, Auth0, Keycloak). The platform always receives a Cognito JWT with standardized claims — never the upstream IdP token.

---

## Additional components

| Component | Type | Role |
|---|---|---|
| AWS Cognito User Pool | AWS | Federation hub and token normalization |
| Cognito App Client (per tenant) | AWS | Per-tenant IdP configuration |
| Cognito Hosted UI | AWS | Login UI at `auth.wasp.silvios.me` |
| Cognito Pre-Token Generation Lambda | AWS | Injects `tenant_id` into the JWT based on the App Client — cannot be forged by the client |
| DynamoDB Global Table `tenant-registry` | AWS | Lookup: email domain → tenant config |
| DynamoDB Global Table `tenant-idp-config` | AWS | Sensitive IdP configuration per tenant |
| AWS Secrets Manager | AWS | External IdP client secrets |
| Discovery Service | Kubernetes | Microservice that queries DynamoDB via IRSA |
| Callback Handler | Kubernetes/Lambda | Exchanges code for tokens, issues session cookie |

---

## Cognito as IdP hub

```
                    ┌─────────────────────────────────┐
                    │         Cognito User Pool       │
                    │                                 │
                    │  App Client: customer1  ────────┼──► Google OIDC
                    │  App Client: customer2  ────────┼──► Microsoft OIDC/SAML
                    │  App Client: customer3  ────────┼──► Okta OIDC
                    │  App Client: customer4  ────────┼──► Auth0 OIDC
                    │  App Client: customer5  ────────┼──► Keycloak OIDC/SAML
                    │  App Client: customer6  ────────┼──► Native Cognito
                    └─────────────────────────────────┘
                                    │
                          JWT Cognito (normalized)
                                    │
                    ┌───────────────▼──────────────────┐
                    │   Istio RequestAuthentication    │
                    │   JWKS: Cognito (single issuer)  │
                    └──────────────────────────────────┘
```

---

## Platform topology

```
           sarah@customer1.com                        motoko@customer2.com
            (California, USA)                            (Tokyo, Japan)
                    │                                          │
                    └─────────────────────┬────────────────────┘
                                          ▼
                                   wasp.silvios.me
                                          │
                                Global Accelerator
                                          │
                    ┌─────────────────────┴────────────────────┐
                    ▼                                          ▼
           platform-us-east-1                         platform-ap-south-1
                    │                                          │
                    ▼                                          ▼
            discovery-service                          discovery-service
                    │                                          │
                    ▼                                          ▼
       customer1.wasp.silvios.me                    customer2.wasp.silvios.me
                    │                                          │
         ┌──────────┴─────────┐                                │
         ▼                    ▼                                ▼
customer1-us-east-1  customer1-us-west-1             customer2-ap-northeast-1
```

---

## Authentication flow

### Summary

```
motoko@customer1.com (Tokyo, Japan)

GET https://wasp.silvios.me                  - Global Accelerator
  - platform-us-east-1.wasp.silvios.me       - US East (N. Virginia)
  - platform-sa-east-1.wasp.silvios.me       - South America (São Paulo)
  - platform-eu-central-1.wasp.silvios.me    - Europe (Frankfurt)
  > platform-ap-south-1.wasp.silvios.me      - Asia Pacific (Mumbai)

GET https://discovery.wasp.silvios.me/tenant?email=motoko@customer1.com
  - customer1.wasp.silvios.me

GET https://customer1.wasp.silvios.me        - Global Accelerator
  - customer1-ap-east-1.wasp.silvios.me      - Asia Pacific (Hong Kong)
  > customer1-ap-northeast-1.wasp.silvios.me - Asia Pacific (Tokyo)
```

### Expanded

```
1. GET https://wasp.silvios.me

   - No cookie → redirect /login


2. User types sarah@customer1.com

   - Frontend extracts domain "customer1.com"


3. GET https://discovery.wasp.silvios.me/tenant?domain=customer1.com

   - DynamoDB lookup by "domain#customer1.com"

   - Returns:

       {
         "client_id": "abc123",
         "tenant_url": "customer1.wasp.silvios.me",
         "idp_name": "Google",
         "idp_issuer": "https://accounts.google.com"
       }


4. Frontend builds the Cognito Hosted UI URL:

   GET https://idp.wasp.silvios.me/oauth2/authorize
     ?client_id=abc123
     &identity_provider=Google
     &redirect_uri=https://auth.wasp.silvios.me/callback
     &response_type=code
     &scope=openid+email+profile
     &state=<signed JWT: tenant_id + nonce + return_url>


5. Cognito redirects to the configured IdP (Google/Microsoft/Okta/etc.)
   
   - User authenticates at their IdP (IdP's own UI)


6. IdP returns to Cognito with code

   - Cognito validates, maps attributes, issues its own tokens

   - Cognito redirects to auth.wasp.silvios.me/callback?code=...


7. Callback handler:

   - Exchanges code for tokens (POST /oauth2/token to Cognito)

   - Decodes state → extracts tenant_id and return_url

   - set-cookie: session=<JWT> Domain=.wasp.silvios.me HttpOnly Secure SameSite=Lax

   - redirect to customer1.wasp.silvios.me


8. customer1.wasp.silvios.me receives request with cookie

   - Istio RequestAuthentication validates JWT (Cognito JWKS)

   - Istio AuthorizationPolicy requires valid JWT

   - App receives claims: sub, email, custom:tenant_id, custom:groups
```

---

## Data structures — DynamoDB

### `tenant-registry` table (DynamoDB Global Table)

Fast email domain lookup to tenant configuration. Replicated across all Global Accelerator regions for local reads with minimal latency.

```json
// Google SSO
{
  "pk": "domain#customer1.com",
  "tenant_id": "customer1",
  "url": "customer1.wasp.silvios.me",
  "regions": ["us-east-1", "us-west-1"],
  "auth": {
    "type": "google_sso",
    "cognito_user_pool_id": "us-east-1_XXXXXX",
    "cognito_app_client_id": "abc123",
    "cognito_idp_name": "Google"
  },
  "status": "active"
}

// Microsoft Azure AD
{
  "pk": "domain#customer2.com",
  "tenant_id": "customer2",
  "url": "customer2.wasp.silvios.me",
  "regions": ["eu-central-1"],
  "auth": {
    "type": "microsoft",
    "cognito_app_client_id": "def456",
    "cognito_idp_name": "MicrosoftAD-Customer2",
    "idp_issuer": "https://login.microsoftonline.com/<azure-tenant-id>/v2.0"
  },
  "status": "active"
}

// Okta
{
  "pk": "domain#customer3.com",
  "tenant_id": "customer3",
  "url": "customer3.wasp.silvios.me",
  "regions": ["us-east-1"],
  "auth": {
    "type": "okta",
    "cognito_app_client_id": "ghi789",
    "cognito_idp_name": "Okta-Customer3",
    "idp_issuer": "https://customer3.okta.com"
  },
  "status": "active"
}

// Auth0
{
  "pk": "domain#customer4.com",
  "tenant_id": "customer4",
  "url": "customer4.wasp.silvios.me",
  "regions": ["us-east-1"],
  "auth": {
    "type": "auth0",
    "cognito_app_client_id": "jkl012",
    "cognito_idp_name": "Auth0-Customer4",
    "idp_issuer": "https://customer4.us.auth0.com"
  },
  "status": "active"
}

// Keycloak self-hosted
{
  "pk": "domain#customer5.com",
  "tenant_id": "customer5",
  "url": "customer5.wasp.silvios.me",
  "regions": ["us-east-1"],
  "auth": {
    "type": "keycloak",
    "cognito_app_client_id": "mno345",
    "cognito_idp_name": "Keycloak-Customer5",
    "idp_issuer": "https://auth.customer5.com/realms/prod"
  },
  "status": "active"
}
```

### `tenant-idp-config` table

Sensitive IdP data, separated for granular IAM access control. Only the callback handler has read permission.

```json
{
  "pk": "tenant#customer3",
  "type": "okta",
  "client_id": "0oaXXXXXXX",
  "client_secret_arn": "arn:aws:secretsmanager:us-east-1:XXXX:secret:customer3-okta-secret",
  "scopes": ["openid", "email", "profile", "groups"],
  "attribute_mapping": {
    "email": "email",
    "name": "name",
    "groups": "custom:groups"
  }
}
```

---

## Integration with the existing lab

| Lab component | Role in the authentication flow |
|---|---|
| **ALB + `*.wasp.silvios.me`** | Routes `auth.wasp.silvios.me` and `discovery.wasp.silvios.me` without changes to the Ingress |
| **Istio `VirtualService`** | Configures CORS for cross-origin calls between subdomains |
| **Istio `RequestAuthentication`** | Validates Cognito JWT — single JWKS regardless of the upstream IdP |
| **Istio `AuthorizationPolicy`** | Blocks requests without a valid JWT **and** rejects JWTs from other tenants via the `custom:tenant_id` claim |
| **WAF** | Rate limiting on `/login` and `/callback` (addresses [SEC-007](security-issues/sec-007.md)) |
| **IRSA** | Discovery service with DynamoDB read permission; callback handler with Secrets Manager access |

### Istio RequestAuthentication configuration

```yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: cognito-jwt
  namespace: istio-ingress
spec:
  jwtRules:
    - issuer: "https://cognito-idp.us-east-1.amazonaws.com/<pool-id>"
      jwksUri: "https://cognito-idp.us-east-1.amazonaws.com/<pool-id>/.well-known/jwks.json"
      forwardOriginalToken: true
```

---

## Tenant isolation via JWT claims

JWT signature validation (`RequestAuthentication`) proves the token is legitimate, but does not prevent a valid JWT from `customer2` from being used to access `customer1` resources. Real isolation is enforced at two complementary layers.

### 1. `tenant_id` injection into the JWT — Cognito Pre-Token Generation Lambda

Each App Client in Cognito is associated with exactly one tenant. A pre-token generation Lambda trigger injects the correct `tenant_id` into the JWT based on the `clientId` used for authentication — the client cannot forge this value:

```python
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('tenant-registry')

def handler(event, context):
    client_id = event['callerContext']['clientId']

    # Lookup tenant_id by App Client ID (GSI on the table)
    response = table.query(
        IndexName='client-id-index',
        KeyConditionExpression='cognito_app_client_id = :cid',
        ExpressionAttributeValues={':cid': client_id}
    )

    tenant_id = response['Items'][0]['tenant_id']

    event['response']['claimsOverrideDetails'] = {
        'claimsToAddOrOverride': {
            'custom:tenant_id': tenant_id
        }
    }
    return event
```

### 2. Enforcement in Istio — AuthorizationPolicy per namespace

Each tenant namespace has its own `AuthorizationPolicy` that requires the JWT `tenant_id` claim to match the tenant owning the namespace. When at least one `AuthorizationPolicy` exists in a namespace, Istio denies everything not explicitly allowed.

```yaml
# namespace: customer1
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-tenant-jwt
  namespace: customer1
spec:
  action: ALLOW
  rules:
    - when:
        - key: request.auth.claims[custom:tenant_id]
          values: ["customer1"]  # only JWTs with custom:tenant_id=customer1 are accepted
```

```yaml
# namespace: customer2 — same structure, different value
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-tenant-jwt
  namespace: customer2
spec:
  action: ALLOW
  rules:
    - when:
        - key: request.auth.claims[custom:tenant_id]
          values: ["customer2"]
```

### Mitigated attack scenario

```
sarah@customer1.com authenticates → receives JWT with tenant_id=customer1

Cross-tenant access attempt:
  GET https://customer2.wasp.silvios.me/api/data
  Cookie: session=<JWT from customer1>

Defense layers:
  1. ALB routes customer2.wasp.silvios.me → Istio IngressGateway  ✓
  2. RequestAuthentication validates JWT signature               ✓ (JWT is valid)
  3. AuthorizationPolicy checks tenant_id == "customer2"        ✗ BLOCKED
     → HTTP 403
```

The token is cryptographically valid — but the wrong `tenant_id` makes it useless outside its own tenant's namespace.

### Defense in depth

| Layer | Mechanism | What it validates |
|---|---|---|
| ALB | Host-based routing | Correct subdomain reaches the cluster |
| Istio IngressGateway | `VirtualService` per Host | Routing to the correct tenant namespace |
| Istio `RequestAuthentication` | Cognito JWKS | JWT signature and expiration |
| Istio `AuthorizationPolicy` | `tenant_id` claim | JWT belongs to the namespace's tenant |

---

## Challenges by IdP type

### Google and Microsoft
- Simpler configuration — native OIDC support in Cognito
- Microsoft: each company has its own Azure AD tenant with a different `issuer` (`https://login.microsoftonline.com/<tenant-id>/v2.0`) — each App Client points to the correct issuer

### Okta and Auth0
- Work as full OIDC providers — Cognito sees them as external IdPs via OIDC federation
- Auth0 can aggregate other IdPs internally — Cognito only sees Auth0, not the upstream IdP
- Custom claim mapping (groups, roles) requires attribute mapping configuration in Cognito

### Keycloak self-hosted
- OIDC or SAML support — OIDC is preferred
- **Critical risk:** requires network connectivity between AWS and the customer's server
  - Option 1: Customer exposes Keycloak publicly with TLS
  - Option 2: AWS PrivateLink + site-to-site VPN
  - Option 3: Customer migrates to Keycloak Cloud (managed)
- If the customer's Keycloak becomes unavailable, the entire tenant's login breaks — **platform SLA is coupled to the customer's infrastructure**

---

## Challenges and resolutions

| Challenge | Impact | Resolution |
|---|---|---|
| CORS between `wasp.silvios.me` and `customer1.wasp.silvios.me` | AJAX requests blocked | OAuth redirects are not subject to CORS; for AJAX, configure `Access-Control-Allow-Origin` in the Istio `VirtualService` |
| Google/Microsoft redirect URI requires pre-registration | Does not scale with N tenants | Centralized callback `auth.wasp.silvios.me/callback` — single URI registered with all IdPs |
| Cognito: limit of 300 external IdPs per User Pool | ~300 tenant ceiling per pool | Multiple User Pools per region or tier |
| Custom attributes vary by IdP | JWT with inconsistent fields | Attribute mapping in Cognito + fixed claims schema on the platform |
| Cross-domain token renewal | `.wasp.silvios.me` cookie expires, transparent refresh needed | Centralized callback handler manages refresh; application does not need to implement it |
| Keycloak/IdP unavailable | Login broken for the tenant | IdP health check in discovery + tenant-contextualized error page |
| customer1 JWT used to access customer2 | Data leak between tenants | `AuthorizationPolicy` per namespace validates `tenant_id` claim — valid but wrong-tenant JWT gets HTTP 403 |
| New tenant onboarding | Create App Client + configure IdP + register in DynamoDB | Onboarding API (Lambda + DynamoDB + Cognito SDK) — the most operational point in the system |

---

## API contracts

### Discovery Service — `GET /tenant`

```
GET /tenant?domain=gmail.com

200 OK
{
  "tenant_id": "customer1",
  "tenant_url": "customer1.wasp.silvios.me",
  "client_id": "<cognito-app-client-id>",
  "idp_name": "Google",
  "idp_pool_id": "<pool-id>"
}

404 Not Found
{
  "detail": "Tenant not found for domain: gmail.com"
}
```

### Callback Handler — `GET /callback`

```
GET /callback?code=<code>&state=<state-jwt>

1. Decode state JWT → { tenant_id, nonce, return_url }
2. POST https://idp.wasp.silvios.me/oauth2/token
     grant_type=authorization_code
     code=<code>
     client_id=<app-client-id>
     redirect_uri=https://auth.wasp.silvios.me/callback
3. Receive id_token (Cognito JWT with custom:tenant_id)
4. Validate that token.tenant_id == state.tenant_id
5. Set-Cookie: session=<id_token>; Domain=.wasp.silvios.me; HttpOnly; Secure; SameSite=Lax
6. 302 → https://<return_url>
```

---

## Open decisions

See [technical-decisions.md](technical-decisions.md) for the detailed record of each pending decision and the trade-offs considered.
