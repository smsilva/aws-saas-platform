# Proposal: LAB-REL-01~03 + LAB-COST-01 — Karpenter, PDB, and Topology Spread

## Problem

The cluster uses Cluster Autoscaler with a static node group, has no pod disruption budgets, and does not spread pods across availability zones. A single AZ failure or node drain can take down all replicas of a service. There is no cost differentiation between platform and tenant workloads.

## Scope

Replace Cluster Autoscaler with Karpenter. Add `topologySpreadConstraints` and `PodDisruptionBudget` to all critical service Deployments. Configure Karpenter NodePools to use On-Demand for platform/auth and Spot for tenant namespaces.

### Items Covered

- **LAB-REL-01**: Karpenter installation and NodePool configuration
- **LAB-REL-02**: `topologySpreadConstraints` on all Deployments
- **LAB-REL-03**: `PodDisruptionBudget` (minAvailable: 1) on all critical services
- **LAB-COST-01**: Spot instance NodePool for tenant workloads

## Relation to Other Changes

- **LAB-SUS-01** (Graviton3) builds on the Karpenter NodePool defined here
