# Traffic Flow

## Ingress stack

```
Internet
   │
   ▼
wasp.silvios.me  (DNS APEX → Global Accelerator static anycast IPs)
   │
   ▼
AWS ALB  (public subnets, HTTPS terminated via ACM)
   │       WAF WebACL: CRS + KnownBadInputs + IP Reputation + rate limiting
   │       Shield Standard: active by default
   ▼
Istio IngressGateway  (namespace: istio-ingress, ClusterIP)
   │       pods in private subnets, traffic via target-type ip
   ▼
Istio Gateway + VirtualService  (routing by Host header)
   ▼
Application  (namespace with sidecar injection)
   │
   Istio RequestAuthentication + AuthorizationPolicy
   (Cognito JWT validation + tenant isolation)
```

## Detailed layers

### ALB

- **Subnets:** public (`10.0.1.0/24`, `10.0.2.0/24`) in `us-east-1a` and `us-east-1b`
- **TLS termination:** wildcard certificate `*.wasp.silvios.me` via ACM
- **HTTP→HTTPS redirect:** configured via annotation on the Ingress
- **Target:** Istio IngressGateway as `ClusterIP`, using `target-type: ip` (pods are the target, not a NodePort)
- **Provisioned by:** AWS Load Balancer Controller `v3.2.1` from the `Ingress` + `IngressClass` resources

### WAF

The WebACL associated with the ALB applies the following rules in order:

| Rule | Protection |
|---|---|
| `AWSManagedRulesCommonRuleSet` | XSS, SQLi, and other common application attack vectors |
| `AWSManagedRulesKnownBadInputsRuleSet` | Known malicious inputs (Log4Shell, etc.) |
| `AWSManagedRulesAmazonIpReputationList` | IPs from botnets and known attack infrastructure |
| Rate limit `/login` | 100 req/5min per IP — protection against credential brute-force |
| Rate limit `/callback` | 100 req/5min per IP — protection against authorization code replay |

!!! info "Shield Standard"
    AWS Shield Standard is active by default on all AWS resources (ALB, CloudFront) at no additional cost. Provides protection against layer 3 and 4 DDoS attacks.

### Istio IngressGateway

- **Namespace:** `istio-ingress`
- **Service type:** `ClusterIP` — no dedicated NLB, receives traffic directly from the ALB via pod IPs
- **Installed via:** Helm (`istio/gateway`)
- **Responsibility:** receive all external traffic and forward it based on `Gateway` and `VirtualService` resources

### Istio Gateway + VirtualService

Each subdomain has a `VirtualService` that routes traffic to the correct service based on the `Host` header:

```
wasp.silvios.me           → platform-frontend.platform.svc.cluster.local
auth.wasp.silvios.me      → callback-handler.auth.svc.cluster.local
discovery.wasp.silvios.me → discovery.discovery.svc.cluster.local
customer1.wasp.silvios.me → <app>.customer1.svc.cluster.local
```

### Istio RequestAuthentication + AuthorizationPolicy

In tenant namespaces (e.g. `customer1`), Istio validates the JWT present in the `session` cookie:

- **`RequestAuthentication`:** configures the Cognito JWKS URI for token signature validation
- **`AuthorizationPolicy`:** rejects requests without a valid JWT (`notRequestPrincipals: ["*"]`) and optionally restricts by claim (`azp`, `cognito:groups`)

This ensures that a token issued for `customer1` is not accepted in namespace `customer2`.

## Security Groups

Cluster, node, and ALB Security Groups are created **automatically** by `eksctl` and the ALB Controller — no Security Groups are explicitly defined in the scripts.

!!! warning "SEC-005"
    Auto-managed Security Groups allow `0.0.0.0/0` inbound on the ALB by default. For production, dedicated Security Groups with source IP restrictions are recommended. See [SEC-005](../security/issues/sec-005.md).
