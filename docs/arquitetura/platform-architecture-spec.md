# Platform Architecture

## Purpose

Define the traffic routing stack for the WASP SaaS platform, from the public internet to tenant workloads running on EKS.

## Requirements

### Requirement: TLS Termination at the Edge

The system SHALL terminate TLS at the ALB using an ACM wildcard certificate for `*.wasp.silvios.me` before forwarding traffic inward.

#### Scenario: HTTP request is upgraded

WHEN a client sends an HTTP request to any platform subdomain
THEN the ALB SHALL redirect it to HTTPS with a 301 response

### Requirement: Static IP Ingress via Global Accelerator

The system SHALL expose static anycast IPs via AWS Global Accelerator so that DNS A records for `wasp.silvios.me` remain stable across ALB replacements.

### Requirement: WAF Protection on ALB

The system SHALL associate a WAFv2 WebACL with the ALB that applies, in order:
- `AWSManagedRulesCommonRuleSet` (XSS, SQLi)
- `AWSManagedRulesKnownBadInputsRuleSet` (Log4Shell and known malicious inputs)
- `AWSManagedRulesAmazonIpReputationList` (botnet IPs)
- Rate limiting on `/login` and `/callback` (100 req / 5 min per IP)

### Requirement: Private Ingress Gateway

The system SHALL run the Istio IngressGateway as a `ClusterIP` service in private subnets, reachable only from the ALB using `target-type: ip`.

### Requirement: Host-Based Routing

The system SHALL route traffic to the correct tenant namespace based on the HTTP `Host` header, with one `VirtualService` per subdomain:

| Host | Destination |
|---|---|
| `wasp.silvios.me` | `platform-frontend.platform` |
| `auth.wasp.silvios.me` | `callback-handler.auth` |
| `discovery.wasp.silvios.me` | `discovery.discovery` |
| `<tenant>.wasp.silvios.me` | workload in `<tenant>` namespace |

### Requirement: JWT Enforcement at the Mesh Layer

The system SHALL validate JWT tokens in tenant namespaces using Istio `RequestAuthentication` with the Cognito JWKS URI.

#### Scenario: Request without JWT is rejected

WHEN a request reaches a tenant namespace without a valid `session` cookie or `Authorization: Bearer` header
THEN the Istio `AuthorizationPolicy` SHALL respond with HTTP 403

#### Scenario: JWT from another tenant is rejected

WHEN a request carries a cryptographically valid JWT but with a `custom:tenant_id` claim that does not match the target namespace
THEN the Istio `AuthorizationPolicy` SHALL respond with HTTP 403

### Requirement: Sidecar Injection on Tenant Namespaces

The system SHALL enable Istio sidecar injection on all tenant namespaces via the `istio-injection: enabled` label.
