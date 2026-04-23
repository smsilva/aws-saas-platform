# Design: LAB-REL-01~03 + LAB-COST-01 — Karpenter, PDB, and Topology Spread

**Karpenter** replaces Cluster Autoscaler. Configure two NodePools: On-Demand for platform/auth, Spot with fallback for tenant namespaces.

**TopologySpread + PDB** — add to each Deployment manifest:

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: <service>
---
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: <service>
```

Tenant NodePool uses `karpenter.sh/capacity-type: spot` toleration; platform NodePool uses `on-demand` only.
