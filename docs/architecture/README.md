# Architecture

The lab provisions a multi-tenant SaaS platform on EKS. The infrastructure layer covers VPC, ALB, WAF, and Istio. The authentication layer adds Cognito as an identity federation hub, DynamoDB for tenant registry, and three microservices that orchestrate the login flow.

## Topology diagram

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
customer1-us-east-1  customer1-us-west-1         customer2-ap-east-1
```

## Subdomains and routing

| Subdomain | Destination | K8s Namespace | Via |
|---|---|---|---|
| `wasp.silvios.me` | platform-frontend | `platform` | ALB → Istio |
| `idp.wasp.silvios.me` | Cognito Hosted UI | — | CloudFront (Azure DNS CNAME) |
| `auth.wasp.silvios.me` | callback-handler | `auth` | ALB → Istio |
| `discovery.wasp.silvios.me` | discovery service | `discovery` | ALB → Istio |
| `customer1.wasp.silvios.me` | tenant app | `customer1` | ALB → Istio |

!!! note "DNS"
    The domain `wasp.silvios.me` is managed in **Azure DNS** (subscription `wasp-sandbox`, resource group `wasp-foundation`), not in Route 53. Scripts use `az network dns record-set` instead of `aws route53`.

## Key resources

| Resource | Identifier |
|---|---|
| EKS Cluster | `wasp-calm-crow-ndx4` |
| Region | `us-east-1` |
| VPC | `vpc-03cb9d83815b52ee1` |
| ACM Certificate | `arn:aws:acm:us-east-1:221047292361:certificate/59ab7614-fa1b-4dba-9f43-7c775cfa5bac` |

## Pages in this section

- [Traffic Flow](traffic-flow.md) — details of the ALB → WAF → Istio → App stack
- [Multi-tenant Authentication](../multi-tenant-auth-flow.md) — login flow, Cognito, DynamoDB, and JWT isolation
- [Technical Decisions](../technical-decisions.md) — trade-offs and open decision backlog
