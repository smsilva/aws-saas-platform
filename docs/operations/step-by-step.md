# Step-by-Step — Infrastructure

## Prerequisites

- `aws` CLI configured with sufficient permissions (IAM, VPC, EKS, ACM, WAF)
- `eksctl` installed
- `helm` installed
- `kubectl` installed
- Wildcard certificate for `*.wasp.silvios.me` in `~/certificates/config/live/wasp.silvios.me/`

## Initial configuration

Edit `scripts/env.conf` before running any script:

```bash
aws_region="us-east-1"
instance_name="wasp"           # logical instance name — used by global resources (Global Accelerator, etc.)
cluster_name="wasp-calm-crow-ndx4"  # EKS cluster name — used by resources provisioned for this cluster
domain="wasp.silvios.me"
az_subscription="wasp-sandbox"    # Azure subscription where the DNS zone lives
az_resource_group="wasp-foundation" # Azure resource group for the DNS zone
cert_arn=""  # fill in at step 06, after importing the cert in ACM
```

Use `scripts/env.conf.example` as a starting point.

---

## 01. Create VPC

```bash
./scripts/01-create-vpc
```

Creates the `10.0.0.0/16` VPC with:

- 2 public subnets (`10.0.1.0/24`, `10.0.2.0/24`) in `us-east-1a` and `us-east-1b`
- 2 private subnets (`10.0.3.0/24`, `10.0.4.0/24`) in `us-east-1a` and `us-east-1b`
- Internet Gateway, NAT Gateway (with EIP), and route tables

Resource IDs are saved in `.vpc-ids` for use in subsequent steps.

## 02. Create EKS cluster

```bash
./scripts/02-create-cluster
```

Creates the cluster via `eksctl` using the VPC from the previous step:

- `t3.medium` nodes in private subnets (managed node group, 2–5 nodes)
- OIDC provider enabled (`withOIDC: true`) — required for IRSA

!!! warning "SEC-006"
    By default `eksctl` does not enforce IMDSv2 on nodes. See [SEC-006](../security-issues/sec-006.md).

## 03. Configure access

```bash
./scripts/03-configure-access
```

Updates the local `kubeconfig` and creates an access entry with `AmazonEKSClusterAdminPolicy` for the current IAM caller.

!!! warning "SEC-004"
    The `AmazonEKSClusterAdminPolicy` policy has cluster-wide scope. See [SEC-004](../security-issues/sec-004.md).

## 04. Install ALB Controller

```bash
./scripts/04-install-alb-controller
```

1. Downloads the official IAM policy from the controller repository
2. Creates the IAM policy in the AWS account
3. Creates the IAM service account with IRSA via `eksctl`
4. Installs the controller via Helm

!!! warning "SEC-002"
    The IAM policy is downloaded without SHA256 hash verification. See [SEC-002](../security-issues/sec-002.md).

## 05. Install Istio

```bash
./scripts/05-install-istio
```

Installs Istio via Helm in the correct order:

1. `istio-base` — CRDs
2. `istiod` — control plane
3. `istio-ingressgateway` — gateway as `ClusterIP` (no dedicated NLB)

## 06. Import certificate into ACM

```bash
./scripts/06-import-certificate-acm
```

Imports the Let's Encrypt certificate from `~/certificates/config/live/wasp.silvios.me/` into ACM and automatically updates `cert_arn` in `env.conf`.

## 07. Configure ALB via Ingress

```bash
./scripts/07-configure-alb-ingress
```

Creates the ALB via classic Kubernetes Ingress:

- `IngressClass` with `controller: ingress.k8s.aws/alb`
- `Ingress` with HTTP→HTTPS redirect, TLS terminated via ACM
- Routing of `*.wasp.silvios.me` to the Istio IngressGateway

At the end, automatically creates the wildcard CNAME record in Azure DNS:

```
*.wasp.silvios.me → <alb-hostname>.us-east-1.elb.amazonaws.com
```

!!! info "Apex not covered by the wildcard"
    The apex record `wasp.silvios.me` is created in step 07b with static IPs from Global Accelerator (CNAME at apex is invalid per RFC 1034; Azure DNS does not support ALIAS for external ALBs).

!!! warning "SEC-005"
    ALB Security Groups are created automatically by the controller, without source IP restriction. See [SEC-005](../security-issues/sec-005.md).

## 07b. Configure Global Accelerator

```bash
./scripts/07b-configure-global-accelerator
```

Provisions the Global Accelerator (`${instance_name}-ga`) pointing to the ALB and creates the apex A records in Azure DNS:

```
wasp.silvios.me → <ip1>, <ip2>  (static anycast IPs from Global Accelerator)
```

The accelerator name uses `instance_name` (not `cluster_name`) because it is a global resource — it can survive cluster replacements and, in the future, serve multiple regions. The ARN is automatically saved in `env.conf` for use by `destroy`.

## 08. Deploy sample app

```bash
./scripts/08-deploy-sample-app
```

Deploys `httpbin` to validate the full flow:

- `sample` namespace with `istio-injection: enabled`
- Istio `Gateway` + `VirtualService` for `httpbin.wasp.silvios.me`

Validation:

```bash
curl https://httpbin.wasp.silvios.me/get
```

!!! warning "SEC-003"
    The `kennethreitz/httpbin` image is used without a pinned digest. See [SEC-003](../security-issues/sec-003.md).

## 09. Configure WAF

```bash
./scripts/09-configure-waf
```

Creates a WebACL with AWS Managed Rules and associates it with the ALB:

| Rule | Protection |
|---|---|
| `AWSManagedRulesCommonRuleSet` | XSS, SQLi, and other common attack vectors |
| `AWSManagedRulesKnownBadInputsRuleSet` | Known malicious inputs |
| `AWSManagedRulesAmazonIpReputationList` | Malicious IPs and botnets |

!!! info "SEC-007 (Resolved)"
    Rate limiting is not included in this script — it is added in step 15. See [SEC-007](../security-issues/sec-007.md).

## 10. Create DynamoDB table

```bash
./scripts/10-create-dynamodb
```

Creates the `tenant-registry` table and inserts the example item for `customer1.com`.

## 11. Create Cognito User Pool

```bash
export GOOGLE_CLIENT_ID="..."
export GOOGLE_CLIENT_SECRET="..."
./scripts/11-create-cognito
```

Creates the User Pool with:

- Google as Identity Provider (OIDC)
- App Client with client credentials
- Pre-Token Generation Lambda (claim customization)

!!! info "Google redirect URI"
    Add `https://idp.wasp.silvios.me/oauth2/idpresponse` to **Authorized redirect URIs** in the Google Cloud Console (not in JavaScript origins — the flow is a server-side redirect).

## 12. Configure Cognito DNS

```bash
./scripts/12-configure-dns-cognito
```

Configures the custom domain `idp.wasp.silvios.me` for the Cognito Hosted UI and creates the CNAME in Azure DNS.

## 13. Deploy services

```bash
export COGNITO_CLIENT_SECRET_CUSTOMER1="..."   # aws cognito-idp describe-user-pool-client --query UserPoolClient.ClientSecret
export STATE_JWT_SECRET="..."        # openssl rand -hex 32
./scripts/13-deploy-services
```

- Builds and pushes Docker Hub images (tag = git short SHA)
- Creates the IRSA for the discovery service (`dynamodb:GetItem`)
- Deploys the 4 namespaces: `platform`, `auth`, `discovery`, `customer1`

## 14. Configure Istio authentication

```bash
./scripts/14-configure-istio-auth
```

Applies in the `customer1` namespace:

- `RequestAuthentication` — validates JWT via Cognito JWKS URI
- `AuthorizationPolicy` — rejects requests without a valid JWT

## 15. Configure WAF rate limiting

```bash
./scripts/15-configure-waf-ratelimit
```

Adds rate limiting rules to the existing WebACL:

- `/login` — 100 requests/5 min per IP
- `/callback` — 100 requests/5 min per IP

## 16. Register IdP and tenant

```bash
echo "${AZURE_CLIENT_SECRET}" | ./scripts/configure-idps \
  --tenant customer2 \
  --provider microsoft \
  --domain msn.com \
  --client-id "${AZURE_CLIENT_ID}" \
  --client-secret-stdin
```

Registers an IdP (Google or Microsoft) + Cognito App Client + DynamoDB item for a tenant.
Use `--provider google` for tenants with a Google IdP.

## 17. Deploy customer2

```bash
./scripts/17-deploy-customer2
```

Deploys the `customer2` namespace with:

- `RequestAuthentication` + `AuthorizationPolicy` configured for the tenant
- Callback handler updated with the customer2 client secret

---

## Required environment variables

Scripts 11 and 13 require environment variables that **do not go** in `env.conf`:

| Variable | Used in | How to obtain |
|---|---|---|
| `GOOGLE_CLIENT_ID` | `11-create-cognito` | Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client ID |
| `GOOGLE_CLIENT_SECRET` | `11-create-cognito` | Same location as Client ID |
| `COGNITO_CLIENT_SECRET_CUSTOMER1` | `13-deploy-services` | `aws cognito-idp describe-user-pool-client --query UserPoolClient.ClientSecret` |
| `STATE_JWT_SECRET` | `13-deploy-services` | `openssl rand -hex 32` |
