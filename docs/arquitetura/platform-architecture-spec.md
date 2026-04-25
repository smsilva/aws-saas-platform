# Platform Architecture

## Purpose

Define the traffic routing stack for the WASP SaaS platform, from the public internet to tenant workloads running on EKS.

## Requirements

### TLS Termination at the Edge

TLS terminates at the ALB using an ACM wildcard certificate for `*.wasp.silvios.me` before forwarding traffic inward. HTTP requests to any platform subdomain are redirected to HTTPS with a 301 response.

### Static IP Ingress via Global Accelerator

Static anycast IPs are exposed via AWS Global Accelerator so that DNS A records for `wasp.silvios.me` remain stable across ALB replacements.

### WAF Protection on ALB

A WAFv2 WebACL is associated with the ALB and applies these rules in order:
- `AWSManagedRulesCommonRuleSet` (XSS, SQLi)
- `AWSManagedRulesKnownBadInputsRuleSet` (Log4Shell and known malicious inputs)
- `AWSManagedRulesAmazonIpReputationList` (botnet IPs)
- Rate limiting on `/login` and `/callback` (100 req / 5 min per IP)

### Private Ingress Gateway

The Istio IngressGateway runs as a `ClusterIP` service in private subnets, reachable only from the ALB using `target-type: ip`.

### Host-Based Routing

Traffic is routed to the correct tenant namespace based on the HTTP `Host` header, with one `VirtualService` per subdomain:

| Host | Destination |
|---|---|
| `wasp.silvios.me` | `platform-frontend.platform` |
| `auth.wasp.silvios.me` | `callback-handler.auth` |
| `discovery.wasp.silvios.me` | `discovery.discovery` |
| `<tenant>.wasp.silvios.me` | workload in `<tenant>` namespace |

### JWT Enforcement at the Mesh Layer

JWT tokens are validated in tenant namespaces using Istio `RequestAuthentication` with the Cognito JWKS URI. Requests without a valid `session` cookie or `Authorization: Bearer` header are rejected with HTTP 403. Requests carrying a valid JWT whose `custom:tenant_id` claim does not match the target namespace are also rejected with HTTP 403.

### Sidecar Injection on Tenant Namespaces

Istio sidecar injection is enabled on all tenant namespaces via the `istio-injection: enabled` label.