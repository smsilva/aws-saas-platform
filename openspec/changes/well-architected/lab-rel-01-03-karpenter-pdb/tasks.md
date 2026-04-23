# Tasks: LAB-REL-01~03 + LAB-COST-01 — Karpenter, PDB, and Topology Spread

## Checklist

- [ ] Uninstall Cluster Autoscaler
- [ ] Install Karpenter via Helm
- [ ] Configure `NodePool` for platform/auth (On-Demand `m7i.large`)
- [ ] Configure `NodePool` for customer namespaces (Spot `m7i.large` with On-Demand fallback) — covers LAB-COST-01
- [ ] Add `topologySpreadConstraints` (zone spread) to all service Deployments
- [ ] Add `PodDisruptionBudget` (minAvailable: 1) to all critical services
