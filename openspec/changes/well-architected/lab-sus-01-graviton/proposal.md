# Proposal: LAB-SUS-01 — Graviton3 Node Preference

## Problem

Karpenter NodePools are configured with x86 instance families (`m7i`, `t3`). Graviton3 instances (`m7g`, `t4g`) offer better price/performance and lower energy consumption for most workloads.

## Scope

Update Karpenter NodePools to prefer `m7g` and `t4g` Graviton3 instance families. Validate that all container images are built for `linux/arm64` or use multi-arch manifests.

## Relation to Other Changes

- **Prerequisite**: LAB-REL-01~03 (Karpenter must be installed and NodePools defined)
