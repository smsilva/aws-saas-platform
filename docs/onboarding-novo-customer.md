# New Customer Onboarding

This document describes the steps to register a new tenant on the platform, including IdP configuration in Cognito, registration in DynamoDB, and deployment of the isolated namespace in the cluster.

---

## Overview

Each tenant is identified by one or more email domains. When logging in, `platform-frontend` extracts the domain from the email, queries the `discovery service` (DynamoDB), and redirects to the correct IdP via Cognito.

Onboarding involves three layers:

```
1. IdP in Cognito     — OAuth credentials for the customer's identity provider
2. DynamoDB           — domain → tenant_id → App Client mapping
3. Kubernetes         — isolated namespace with Istio auth (RequestAuthentication + AuthorizationPolicy)
```

---

## Initial decision: new IdP or existing?

Before starting, answer:

> **Does the customer use an IdP already registered on the platform (same Client ID and Client Secret)?**

| Situation | Path |
|---|---|
| New IdP (own credentials) | Follow all steps below |
| Shared IdP (same Client ID already registered) | Skip Step 1; register only the additional domain in DynamoDB pointing to the existing App Client |

The shared IdP case is detailed in the [Multiple domains on the same IdP](#multiple-domains-on-the-same-idp) section.

---

## Step 1 — Configure the IdP in Cognito

### 1.1 Determine the IdP type

| Type | `provider-type` in AWS CLI | When to use |
|---|---|---|
| Google (personal account / Workspace) | `OIDC` with `oidc_issuer=https://accounts.google.com` | Maximum one `Google` (social) IdP per User Pool — use OIDC for the others |
| Microsoft (MSA personal accounts) | `OIDC` with fixed GUID issuer `9188040d-6c67-4c5b-b112-36a304b66dad` | See `docs/decisoes-tecnicas.md` |
| Microsoft (corporate Azure AD / Google Workspace federated via AD) | `OIDC` with `oidc_issuer=https://login.microsoftonline.com/<tenant-id>/v2.0` | Use the organization's real tenant ID |
| Any other OIDC provider | `OIDC` | Okta, Auth0, Keycloak, etc. |

### 1.2 Prerequisites at the identity provider

Before running any script, register the application in the provider's console and obtain:

- `CLIENT_ID`
- `CLIENT_SECRET`
- Required redirect URI: `https://idp.<domain>/oauth2/idpresponse`

> For Google, the redirect URI goes in **Authorized redirect URIs** (not in Authorized JavaScript origins). Changes take up to 5 minutes to propagate.

### 1.3 Create the IdP in Cognito

```bash
export CUSTOMER_CLIENT_ID=<client-id from the provider>
export CUSTOMER_CLIENT_SECRET=<client-secret>

idp_name="<IdPName-CustomerN>"          # e.g.: Google-Customer3, AzureAD-Customer4
oidc_issuer="<provider issuer>"
tenant_id="customerN"                    # e.g.: customer3

aws cognito-idp create-identity-provider \
  --region "${aws_region}" \
  --user-pool-id "${cognito_user_pool_id}" \
  --provider-name "${idp_name}" \
  --provider-type OIDC \
  --provider-details \
    "client_id=${CUSTOMER_CLIENT_ID},client_secret=${CUSTOMER_CLIENT_SECRET},authorize_scopes=openid email profile,oidc_issuer=${oidc_issuer},attributes_request_method=GET" \
  --attribute-mapping \
    "email=email,name=name"
```

### 1.4 Create the App Client in Cognito

```bash
app_client_id=$(
  aws cognito-idp create-user-pool-client \
    --region "${aws_region}" \
    --user-pool-id "${cognito_user_pool_id}" \
    --client-name "${tenant_id}" \
    --generate-secret \
    --supported-identity-providers "${idp_name}" \
    --allowed-o-auth-flows code \
    --allowed-o-auth-scopes openid email profile \
    --callback-urls "https://auth.${domain}/callback" \
    --logout-urls "https://${tenant_id}.${domain}/logout" \
    --allowed-o-auth-flows-user-pool-client \
    --query 'UserPoolClient.ClientId' \
    --output text
)
```

### 1.5 Retrieve the App Client Secret

```bash
export COGNITO_CUSTOMERX_CLIENT_SECRET=$(
  aws cognito-idp describe-user-pool-client \
    --region "${aws_region}" \
    --user-pool-id "${cognito_user_pool_id}" \
    --client-id "${app_client_id}" \
    --query UserPoolClient.ClientSecret \
    --output text
)
```

---

## Step 2 — Register the domain in DynamoDB

Each email domain gets an item in `tenant-registry`. The primary key is `domain#<domain>`.

```bash
tenant_domain="<email domain>"           # e.g.: empresa.com
tenant_url="${tenant_id}.${domain}"       # e.g.: customer3.wasp.silvios.me

item=$(cat <<EOF
{
  "pk":                    {"S": "domain#${tenant_domain}"},
  "tenant_id":             {"S": "${tenant_id}"},
  "url":                   {"S": "${tenant_url}"},
  "regions":               {"L": [{"S": "${aws_region}"}]},
  "cognito_app_client_id": {"S": "${app_client_id}"},
  "auth": {"M": {
    "type":                  {"S": "oidc"},
    "cognito_user_pool_id":  {"S": "${cognito_user_pool_id}"},
    "cognito_app_client_id": {"S": "${app_client_id}"},
    "cognito_idp_name":      {"S": "${idp_name}"}
  }},
  "status": {"S": "active"}
}
EOF
)

aws dynamodb put-item \
  --region "${aws_region}" \
  --table-name "tenant-registry" \
  --item "${item}"
```

### Verify

```bash
curl "https://discovery.${domain}/tenant?domain=${tenant_domain}"
```

---

## Step 3 — Update the callback-handler

The `callback-handler` needs to know each tenant's Client Secret to exchange the code for a token.

Add the new key to the existing Secret:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: callback-handler-secret
  namespace: auth
type: Opaque
stringData:
  COGNITO_CLIENT_SECRET_CUSTOMER1: "${COGNITO_CLIENT_SECRET_CUSTOMER1}"
  COGNITO_CLIENT_SECRET_CUSTOMER2: "${COGNITO_CUSTOMER2_CLIENT_SECRET}"
  COGNITO_CLIENT_SECRET_CUSTOMERX: "${COGNITO_CUSTOMERX_CLIENT_SECRET}"   # new
  STATE_JWT_SECRET: "${STATE_JWT_SECRET}"
EOF

kubectl -n auth rollout restart deployment/callback-handler
kubectl -n auth rollout status deployment/callback-handler --timeout=180s
```

---

## Step 4 — Deploy the tenant namespace

Each tenant gets an isolated namespace with Istio `RequestAuthentication` + `AuthorizationPolicy`.

```bash
jwt_issuer="https://cognito-idp.${aws_region}.amazonaws.com/${cognito_user_pool_id}"
jwks_uri="${jwt_issuer}/.well-known/jwks.json"

kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: ${tenant_id}
  labels:
    istio-injection: enabled
---
# ... Tenant application Deployment, Service, Gateway, VirtualService ...
---
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: cognito-jwt
  namespace: ${tenant_id}
spec:
  jwtRules:
    - issuer: "${jwt_issuer}"
      jwksUri: "${jwks_uri}"
      forwardOriginalToken: true
      fromCookies:
        - session
      fromHeaders:
        - name: Authorization
          prefix: "Bearer "
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-tenant-jwt
  namespace: ${tenant_id}
spec:
  action: ALLOW
  rules:
    - when:
        - key: request.auth.claims[custom:tenant_id]
          values: ["${tenant_id}"]
EOF
```

The `AuthorizationPolicy` ensures that a JWT issued for another tenant is rejected with 403 in this namespace — cross-tenant isolation by design.

---

## End-to-end verification

```bash
# 1. No JWT → should return 403
curl -s -o /dev/null -w '%{http_code}' "https://${tenant_id}.${domain}/get"

# 2. JWT from another tenant → should return 403
curl -s -o /dev/null -w '%{http_code}' \
  -b "session=<JWT from another tenant>" \
  "https://${tenant_id}.${domain}/get"

# 3. Full flow via browser
# Access https://<domain> → type new domain email → authenticate → arrive at <tenant_id>.<domain>
```

---

## Multiple domains on the same IdP

When two or more domains share the same identity provider (same Client ID and Client Secret — for example, corporate groups where all companies are in the same corporate directory), **a new IdP or App Client in Cognito is not needed**.

In this case:

### What changes

| Step | Action |
|---|---|
| Step 1 (IdP + App Client) | **Skip** — reuse the existing App Client from the primary tenant |
| Step 2 (DynamoDB) | **Execute** — register the new domain pointing to the existing `tenant_id` and `app_client_id` |
| Step 3 (callback-handler) | **Skip** — the secret already exists |
| Step 4 (namespace) | Depends: if the new domain belongs to the **same tenant** (same application), skip. If it is a separate logical tenant with its own namespace, execute with a new `tenant_id` |

### Register the additional domain

```bash
new_domain="<second domain>"             # e.g.: subsidiary.com
existing_tenant_id="<existing tenant>"   # e.g.: customer3
existing_app_client_id="<client_id>"

item=$(cat <<EOF
{
  "pk":                    {"S": "domain#${new_domain}"},
  "tenant_id":             {"S": "${existing_tenant_id}"},
  "url":                   {"S": "${existing_tenant_id}.${domain}"},
  "regions":               {"L": [{"S": "${aws_region}"}]},
  "cognito_app_client_id": {"S": "${existing_app_client_id}"},
  "auth": {"M": {
    "type":                  {"S": "oidc"},
    "cognito_user_pool_id":  {"S": "${cognito_user_pool_id}"},
    "cognito_app_client_id": {"S": "${existing_app_client_id}"},
    "cognito_idp_name":      {"S": "<idp_name of the existing tenant>"}
  }},
  "status": {"S": "active"}
}
EOF
)

aws dynamodb put-item \
  --region "${aws_region}" \
  --table-name "tenant-registry" \
  --item "${item}"
```

### Result

Users from both domains (`empresa.com` and `subsidiary.com`) are routed to the same App Client in Cognito, pass through the same IdP, and arrive at the same application namespace. The Pre-Token Generation Lambda injects `custom:tenant_id` based on the App Client ID — both domains receive the same `tenant_id` in the JWT.

> **Note:** if the two domains need logical isolation (different namespaces, different AuthorizationPolicies), create a separate App Client for each logical tenant, even if they share the IdP. The App Client is the unit of isolation in Cognito.

---

## Quick reference — onboarding checklist

```
[ ] Register the application in the identity provider console
    [ ] Obtain CLIENT_ID and CLIENT_SECRET
    [ ] Add redirect URI: https://idp.<domain>/oauth2/idpresponse

[ ] Step 1 — Cognito (skip if IdP already exists)
    [ ] Create IdP (create-identity-provider)
    [ ] Create App Client (create-user-pool-client)
    [ ] Save COGNITO_CUSTOMERX_CLIENT_SECRET

[ ] Step 2 — DynamoDB
    [ ] Register each tenant email domain (put-item)
    [ ] Verify: curl discovery/tenant?domain=<domain>

[ ] Step 3 — callback-handler
    [ ] Add COGNITO_CLIENT_SECRET_CUSTOMERX to the Secret (skip if shared IdP)
    [ ] Restart callback-handler deployment

[ ] Step 4 — Kubernetes
    [ ] Create namespace with istio-injection: enabled
    [ ] Deploy tenant application
    [ ] RequestAuthentication (validate Cognito JWT)
    [ ] AuthorizationPolicy (custom:tenant_id == "<tenant_id>")

[ ] Verification
    [ ] No JWT → 403
    [ ] JWT from another tenant → 403
    [ ] Full flow via browser
```
