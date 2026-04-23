# Tasks: LAB-SUS-01 — Graviton3 Node Preference

## Checklist

- [ ] Verify all service container images have `linux/arm64` or multi-arch manifests
- [ ] Update Karpenter `NodePool` for tenant namespaces to prefer `m7g`, `t4g` instance families
- [ ] Update Karpenter `NodePool` for platform/auth to include `m7g` alongside `m7i`
- [ ] Monitor for scheduling failures after rollout