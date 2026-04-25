# Security Review

Analysis of the lab scripts focused on real risks for production use or as a base for other environments.

## Identified Issues

| ID | Severity | Script | Problem | Status |
|---|---|---|---|---|
| [SEC-002](../security-issues/sec-002.md) | Medium | `04-install-alb-controller` | IAM policy downloaded from GitHub without SHA256 hash verification | Open |
| [SEC-003](../security-issues/sec-003.md) | Low | `08-deploy-sample-app` | `kennethreitz/httpbin` image without fixed tag or digest | Open |
| [SEC-004](../security-issues/sec-004.md) | Medium | `03-configure-access` | `AmazonEKSClusterAdminPolicy` scoped to entire cluster | Open |
| [SEC-005](../security-issues/sec-005.md) | Low | `07-configure-alb-ingress` | ALB Security Groups created automatically, without source IP restriction | Open |
| [SEC-006](../security-issues/sec-006.md) | Medium | `02-create-cluster` | IMDSv1 enabled by default on nodes — credentials accessible via SSRF | Open |
| [SEC-007](../security-issues/sec-007.md) | Low | `09-configure-waf` | WAF without rate limiting — no protection against brute-force or flood | Resolved by script 15 |

## Severity Criteria

| Severity | Criterion |
|---|---|
| **High** | Risk of direct compromise of production credentials or data exfiltration without additional conditions |
| **Medium** | Viable attack vector with significant impact, but requires additional conditions (SSRF, compromised IAM role, etc.) |
| **Low** | Increased attack surface mitigated by other layers; not directly exploitable |

## Summary by Layer

| Layer | Issues | Notes |
|---|---|---|
| IAM | SEC-002, SEC-004 | Excessive permissions and lack of integrity verification during provisioning |
| Container | SEC-003 | Mutable image — implicit `latest` tag may change between lab runs |
| Kubernetes RBAC | SEC-004 | `cluster-admin` without namespace scope increases blast radius of a compromise |
| Network | SEC-005 | Permissive ALB Security Groups — no source IP allowlist |
| Node | SEC-006 | IMDSv1 allows any pod with SSRF to access node credentials |
| WAF | SEC-007 | No rate limiting on authentication endpoints allows brute-force and flood |
