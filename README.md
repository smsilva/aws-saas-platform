# EKS with ALB + Istio Gateway

## Overview

Provision an EKS cluster with public and private VPC, where inbound traffic is delivered by an ALB to the Istio IngressGateway, with WAF and IRSA configured.

## Provisioned Components

| Component | Type | Description |
|---|---|---|
| VPC `10.0.0.0/16` | AWS | Isolated network with 2 public and 2 private subnets in different AZs |
| Internet Gateway | AWS | Inbound and outbound traffic on public subnets |
| NAT Gateway + EIP | AWS | Outbound traffic from private subnets. The EIP (Elastic IP) ensures a fixed public IP for the NAT Gateway |
| Route Tables | AWS | Public routing (via IGW) and private routing (via NAT GW) |
| EKS Cluster | AWS | Managed control plane, version `1.34`, OIDC provider enabled for IRSA |
| Managed Node Group | AWS | 2–5 `t3.medium` nodes in private subnets, IMDSv2 required |
| IAM Access Entry | AWS | `cluster-admin` permission for the caller IAM via EKS Access API |
| AWS Load Balancer Controller `v3.2.1` | Kubernetes | Operator that provisions and manages the ALB from `Ingress` and `IngressClass` resources |
| IAM Role (IRSA) | AWS | Role bound to the ALB Controller service account via OIDC |
| ALB | AWS | Internet-facing load balancer, TLS terminated via ACM, redirects HTTP→HTTPS |
| ACM Certificate | AWS | Let's Encrypt certificate imported for `*.wasp.silvios.me` |
| Istio (`istio-base`) | Kubernetes | Istio CRDs |
| Istio (`istiod`) | Kubernetes | Service mesh control plane (Pilot, Citadel, Galley) |
| Istio IngressGateway | Kubernetes | Ingress gateway as `ClusterIP`, receives traffic from ALB via `target-type: ip` |
| WAF WebACL | AWS | AWS Managed Rules (CRS, KnownBadInputs, IP Reputation) associated with the ALB |
| httpbin | Kubernetes | Sample app for validating the complete ALB → Istio → app flow |

> **Note:** Security Groups (cluster, nodes, and ALB) are created automatically by `eksctl` and the ALB Controller — no SG is explicitly defined in the scripts. See [SEC-005](#security-review) in the security review.

## Architecture

### Traffic Flow

See [docs/architecture/traffic-flow.md](docs/architecture/traffic-flow.md).

### Topology

```
           sara@customer1.com                        motoko@customer2.com
                    │                                          │
                    └─────────────────────┬────────────────────┘
                                          ▼
                                   wasp.silvios.me
                                          │
                                 Global Accelerator
                                          │
                    ┌─────────────────────┴────────────────────┐
                    ▼                                          ▼
         platform-us-east-1-wasp                  platform-eu-central-1-wasp
              (us-east-1)                              (eu-central-1)
                    │                                          │
                    ▼                                          ▼
            discovery-service                          discovery-service
                    │                                          │
                    ▼                                          ▼
       customer1.wasp.silvios.me                 customer2.wasp.silvios.me
                    │                                          │
         ┌──────────┴─────────┐                                │
         ▼                    ▼                                ▼
customer1-us-east-1  customer1-us-west-1             customer2-ap-east-1
```

### Multi-tenant Authentication Flow

The login flow design, including support for multiple IdPs per tenant (Google SSO, Microsoft, Okta, Auth0, Keycloak), DynamoDB data architecture, and integration with Cognito and Istio, is documented in:

- **[Multi-tenant Authentication Architecture](docs/multi-tenant-auth-flow.md)**
- **[Technical Decisions and Trade-offs](docs/technical-decisions.md)**
- **[Customer Onboarding](docs/customer-onboarding.md)**

**Tools:**

- `aws cli`
- `eksctl`
- `helm`

## Prerequisites

- `aws` CLI configured with sufficient permissions
- `eksctl` installed
- `helm` installed
- `kubectl` installed
- Certificate for `*.wasp.silvios.me` available at `~/certificates/config/live/wasp.silvios.me/`

## Configuration

Edit `env.conf` before running the scripts:

```bash
# Variables that need to be reviewed before starting
aws_region="us-east-1"
cluster_name="wasp-calm-crow-ndx4"
domain="wasp.silvios.me"
cert_arn="" # fill in step 06 (after importing the cert into ACM)
```

## Step-by-Step

### 01. Create VPC

```bash
./01-create-vpc
```

Creates the VPC `10.0.0.0/16` with:
- 2 public subnets (`10.0.1.0/24`, `10.0.2.0/24`) in `us-east-1a` and `us-east-1b`
- 2 private subnets (`10.0.3.0/24`, `10.0.4.0/24`) in `us-east-1a` and `us-east-1b`
- Internet Gateway, NAT Gateway (with EIP), and route tables

Resource IDs are saved to `.vpc-ids` for use in subsequent steps.

### 02. Create EKS Cluster

```bash
./02-create-cluster
```

Creates the EKS cluster via `eksctl` using the VPC from the previous step:
- `t3.medium` nodes in private subnets (managed node group)
- OIDC provider enabled (`withOIDC: true`) — required for IRSA

### 03. Configure Access

```bash
./03-configure-access
```

Updates the local `kubeconfig` and creates an access entry with cluster admin permission for the current IAM caller.

### 04. Install ALB Controller

```bash
./04-install-alb-controller
```

Installs the AWS Load Balancer Controller with IRSA:
1. Downloads the official IAM policy from the controller repository
2. Creates the IAM policy in the AWS account
3. Creates the IAM service account with IRSA via `eksctl` (trust policy on the OIDC provider)
4. Installs the controller via Helm

### 05. Install Istio

```bash
./05-install-istio
```

Installs Istio via Helm in the correct order:
1. `istio-base` — CRDs
2. `istiod` — control plane
3. `istio-ingressgateway` — gateway as `ClusterIP` (no dedicated NLB)

### 06. Import Certificate into ACM

```bash
./06-import-certificate-acm
```

Imports the Let's Encrypt certificate from `~/certificates/config/live/wasp.silvios.me/` into AWS Certificate Manager and automatically updates `cert_arn` in `env.conf`.

For this lab, ensure that:
 - The certificate includes the APEX domain `wasp.silvios.me` for:
   - Global Accelerator hostname
   - Cognito Custom Domain
 - The certificate includes the SAN `*.wasp.silvios.me` to cover the ALB hostname created in the next step

Verification:

```shell
openssl x509 -in ~/certificates/config/live/wasp.silvios.me/cert.pem -text -noout | grep -E 'DNS:wasp.silvios.me|DNS:\*\.wasp\.silvios\.me'
```

### 07. Configure ALB via Ingress

```bash
./07-configure-alb-ingress
```

Creates the ALB using the classic Kubernetes Ingress:
- `IngressClass` with `controller: ingress.k8s.aws/alb`
- `Ingress` with HTTP→HTTPS redirect, TLS terminated via ACM
- Routing of `*.wasp.silvios.me` to the Istio IngressGateway

At the end, automatically creates the wildcard CNAME record in Azure DNS:
```
*.wasp.silvios.me → <alb-hostname>.us-east-1.elb.amazonaws.com
```

> **Note:** the apex `wasp.silvios.me` cannot be a CNAME. The apex A record is created in step 07b with the static IPs from Global Accelerator.

### 07b. Configure Global Accelerator

```bash
./07b-configure-global-accelerator
```

Provisions a Global Accelerator with two static anycast IPs pointing to the ALB and creates the apex A records in Azure DNS:

```
wasp.silvios.me → <ip1>, <ip2>  (Global Accelerator fixed IPs)
```

The accelerator name uses `instance_name` (not `cluster_name`) because it is a global resource — it can survive cluster replacements and serve multiple regions in the future.

### 08. Deploy Sample App

```bash
./08-deploy-sample-app
```

Deploys `httpbin` to validate the complete flow:
- Namespace `sample` with `istio-injection: enabled`
- Istio `Gateway` + `VirtualService` for `httpbin.wasp.silvios.me`

Validation:
```bash
curl https://httpbin.wasp.silvios.me/get
```

### 09. Configure WAF

```bash
./09-configure-waf
```

Creates a WebACL with AWS Managed Rules and associates it with the ALB:

| Rule | Protection |
|---|---|
| `AWSManagedRulesCommonRuleSet` | XSS, SQLi, and other common vectors |
| `AWSManagedRulesKnownBadInputsRuleSet` | Known malicious inputs |
| `AWSManagedRulesAmazonIpReputationList` | Malicious IPs and botnets |

**Shield Standard** is active by default on all AWS resources at no additional cost.

## Tear Down the Lab

```bash
./destroy
```

Removes all resources in reverse order. The script waits for each step to complete before proceeding.

> **Note:** the ACM certificate is not removed by the script — delete it manually via the console or `aws acm delete-certificate --certificate-arn <arn>`.

## File Structure

```
lab/aws/eks/
├── env.conf                   # configuration variables
├── 01-create-vpc              # VPC, subnets, IGW, NAT GW, route tables
├── 02-create-cluster          # EKS cluster + node group + OIDC
├── 03-configure-access        # kubeconfig + admin access entry
├── 04-install-alb-controller  # AWS LBC with IRSA
├── 05-install-istio           # istio-base, istiod, istio-ingressgateway
├── 06-import-certificate-acm  # imports Let's Encrypt cert into ACM
├── 07-configure-alb-ingress   # classic Ingress (IngressClass + Ingress → ALB) + wildcard CNAME Azure DNS
├── 07b-configure-global-accelerator  # Global Accelerator → ALB + apex A records Azure DNS
├── 08-deploy-sample-app       # httpbin + Istio Gateway + VirtualService
├── 09-configure-waf           # WAF WebACL + ALB association
└── destroy                    # deletion in reverse order
```

## Documentation

| Location | Content |
|---|---|
| [`docs/architecture/`](docs/architecture/) | Topology, traffic flow, formal component specs |
| [`docs/well-architected-framework/`](docs/well-architected-framework/) | Production roadmap — 17 changes organized by the 6 WAF pillars |
| [`docs/security/`](docs/security/) | Security review, open and closed issues |
| [`docs/operations/`](docs/operations/) | Provisioning step-by-step (scripts 01–17) |
| [`docs/services/`](docs/services/) | Microservices `discovery`, `platform-frontend`, `callback-handler` |
| [`docs/technical-decisions.md`](docs/technical-decisions.md) | Design decisions, trade-offs, and consciously deferred items |
| [`HANDOFF.md`](HANDOFF.md) | Current session state and open tasks |

**For AI agents:** see [`AGENTS.md`](AGENTS.md) (entry point for Cursor, Copilot, Gemini CLI and others) and [`CLAUDE.md`](CLAUDE.md) (Claude Code-specific context).

---

## Security Review

Analysis of the lab scripts focused on real risks for production use or as a base for other environments.

| ID | Severity | Script | Problem |
|---|---|---|---|
| [SEC-002](docs/security/issues/sec-002.md) | Medium | `04-install-alb-controller` | IAM policy downloaded from GitHub without hash verification — supply chain risk |
| [SEC-003](docs/security/issues/sec-003.md) | Low | `08-deploy-sample-app` | `kennethreitz/httpbin` image without fixed tag/digest — implicit `latest` |
| [SEC-004](docs/security/issues/sec-004.md) | Medium | `03-configure-access` | `AmazonEKSClusterAdminPolicy` with cluster-wide scope — unrestricted cluster-admin |
| [SEC-005](docs/security/issues/sec-005.md) | Low | `07-configure-alb-ingress` | ALB Security Groups created automatically — no source IP restriction |
| [SEC-006](docs/security/issues/sec-006.md) | Medium | `02-create-cluster` | IMDSv1 enabled by default — node credentials accessible via SSRF or compromised pod |
| [SEC-007](docs/security/issues/sec-007.md) | Low | `09-configure-waf` | WAF without rate limiting — no protection against brute-force or flood |
