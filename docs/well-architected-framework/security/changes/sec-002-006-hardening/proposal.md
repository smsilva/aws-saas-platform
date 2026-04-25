# Proposal: Security Hardening (SEC-002 to SEC-006)

## Problem

Five open security issues identified during the lab security review remain unaddressed. Three are rated Medium severity and block production readiness. The issues span IAM provisioning, container supply chain, Kubernetes access control, network perimeter, and node metadata access.

## Proposed Change

Fix all five open issues in a single change:

| Issue | Severity | Fix |
|---|---|---|
| SEC-002 | Medium | Add SHA256 hash verification after downloading IAM policy in `04-install-alb-controller` |
| SEC-003 | Low | Pin `kennethreitz/httpbin` to a specific digest in `08-deploy-sample-app` |
| SEC-004 | Medium | Replace `AmazonEKSClusterAdminPolicy` with namespace-scoped access for day-to-day operations |
| SEC-005 | Low | Add `alb.ingress.kubernetes.io/inbound-cidrs` annotation restricting ALB to Global Accelerator IPs |
| SEC-006 | Medium | Set `httpTokens: required` and `httpPutResponseHopLimit: 1` in the eksctl node group config |

## Out of Scope

- Secrets Manager / External Secrets Operator (tracked separately in the well-architected change)
- KMS encryption for etcd (tracked in well-architected)
- WireGuard VPN (tracked in vpn-private-control-plane)

## Success Criteria

- All five issues are marked resolved in `docs/security/index.md`
- `scripts/04-install-alb-controller` verifies the IAM policy hash before applying it
- `scripts/08-deploy-sample-app` uses a pinned image digest
- `scripts/03-configure-access` uses namespace-scoped access or documents the cluster-admin grant as intentional lab-only
- `scripts/07-configure-alb-ingress` includes the `inbound-cidrs` annotation
- `scripts/02-create-cluster` eksctl config has `httpTokens: required`
