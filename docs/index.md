# EKS Lab — ALB + Istio + Multi-tenant Authentication

EKS lab that provisions a complete multi-tenant SaaS platform: VPC with public and private subnets, ALB with TLS, Istio IngressGateway, WAF, and a federated authentication stack with Amazon Cognito and DynamoDB. Supports multiple Identity Providers (Google, Microsoft, Okta, Auth0, Keycloak) per tenant.

## Provisioned components

| Component | Type | Description |
|---|---|---|
| VPC `10.0.0.0/16` | AWS | Isolated network with 2 public and 2 private subnets in different AZs |
| Internet Gateway | AWS | Inbound and outbound traffic on public subnets |
| NAT Gateway + EIP | AWS | Outbound traffic from private subnets with a fixed public IP |
| Route Tables | AWS | Public routing (via IGW) and private routing (via NAT GW) |
| EKS Cluster | AWS | Managed control plane, version `1.34`, OIDC provider enabled for IRSA |
| Managed Node Group | AWS | 2–5 `t3.medium` nodes in private subnets, IMDSv2 required |
| IAM Access Entry | AWS | `cluster-admin` permission for the caller IAM via EKS Access API |
| AWS Load Balancer Controller `v3.2.1` | Kubernetes | Operator that manages the ALB from `Ingress` resources |
| IAM Role (IRSA) | AWS | Role bound to the ALB Controller service account via OIDC |
| ALB | AWS | Internet-facing load balancer, TLS terminated via ACM, redirects HTTP→HTTPS |
| ACM Certificate | AWS | Let's Encrypt certificate imported for `*.wasp.silvios.me` |
| Istio | Kubernetes | `istio-base` (CRDs), `istiod` (control plane), `istio-ingressgateway` (ClusterIP) |
| WAF WebACL | AWS | AWS Managed Rules (CRS, KnownBadInputs, IP Reputation) + rate limiting |
| DynamoDB | AWS | `tenant-registry` table with tenant and IdP configuration |
| Amazon Cognito | AWS | User Pool as federation hub, custom domain on ACM |

For the detailed traffic flow and multi-region topology, see [Architecture](arquitetura/index.md).

## waspctl project

This lab documents Phase 1 of the WASP platform: single cluster, custom Auth Service, and manual multi-tenant authentication via scripts. The [`waspctl`](https://github.com/silviosilva/waspctl) project is being developed as a CLI to automate provisioning of this same topology in Phases 2 and 3 (separate platform-clusters + multi-region expansion with Global Accelerator).

## Navigation

<div class="grid cards" markdown>

-   **Architecture**

    ---

    Topology, detailed traffic flow, multi-tenant authentication, and technical decisions.

    [:octicons-arrow-right-24: View Architecture](arquitetura/index.md)

-   **Operations**

    ---

    Provisioning step-by-step (scripts 01–17), new tenant onboarding, and teardown.

    [:octicons-arrow-right-24: View Operations](operacoes/index.md)

-   **Services**

    ---

    The three Python/FastAPI microservices: Discovery, Platform Frontend, and Callback Handler.

    [:octicons-arrow-right-24: View Services](servicos/index.md)

-   **Security**

    ---

    Security review of the scripts with severity, attack vector, and mitigation status.

    [:octicons-arrow-right-24: View Security](seguranca/index.md)

</div>
