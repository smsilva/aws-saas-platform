# Proposal: LAB-OPS-02 — ArgoCD GitOps

## Problem

Kubernetes manifests are applied via `kubectl apply` in shell scripts with no reconciliation, no drift detection, and no audit trail. A manual change in-cluster is invisible until someone re-runs the script.

## Scope

Install ArgoCD and create one Application per namespace (`platform`, `auth`, `discovery`, `customer1`, `customer2`) pointing to the `platform/` directory in the repo. Remove `kubectl apply` calls for manifests now managed by ArgoCD.

## Relation to Other Changes

- **Prerequisite**: LAB-OPS-01 + LAB-OPS-03 (the `platform/` layer must exist before ArgoCD Applications are created)
