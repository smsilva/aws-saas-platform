@AGENTS.md

# CLAUDE.md — Claude-specific context

## Identifiers

| Resource | Value |
|---|---|
| EKS Cluster | `wasp-cool-whale-7zr5` |
| Region | `us-east-1` |
| AWS Account | `221047292361` |
| Domain | `wasp.silvios.me` (wildcard `*.wasp.silvios.me`) |
| ACM Cert ARN | `arn:aws:acm:us-east-1:221047292361:certificate/3b83625c-895c-461d-a18e-571166508123` |

## Traffic flow

```
Internet → ALB (TLS/ACM) → WAF → Istio IngressGateway (ClusterIP) → VirtualService → App (sidecar)
```

## Infra commands

```bash
./scripts/bootstrap --create    # validate prereqs before provisioning
./scripts/bootstrap --destroy   # validate prereqs before teardown

kubectl get pods -A
helm list -A
```

## Additional rules

- **New AWS/Azure resource:** add deletion entry to `scripts/destroy` in the same session — reverse order, dependency-aware, idempotent (`|| true`)
- **Design ↔ Services:** changes in `lab/aws/eks/design` and `lab/aws/eks/services` must always be kept in sync
- **HANDOFF.md:** update while running lab scripts — record decisions, issues, and solutions

## Imports

@docs/CLAUDE.md
@docs/architecture/CLAUDE.md
@docs/well-architected-framework/CLAUDE.md
@docs/security/CLAUDE.md
