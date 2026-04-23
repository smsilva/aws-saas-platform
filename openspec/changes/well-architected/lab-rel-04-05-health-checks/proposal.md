# Proposal: LAB-REL-04~05 — Health Probes and Circuit Breaking

## Problem

Some service Deployments are missing `livenessProbe` / `readinessProbe`, which means Kubernetes cannot detect hung processes and the load balancer may route traffic to unready pods. There is no circuit-breaking policy on high-traffic services, so a slow downstream cascades into full saturation.

## Scope

Verify and add missing probes to all Deployments. Add Istio `DestinationRule` with `outlierDetection` for `discovery` and `callback-handler`.

### Items Covered

- **LAB-REL-04**: `livenessProbe` + `readinessProbe` audit across all Deployments
- **LAB-REL-05**: Istio `outlierDetection` on discovery and callback-handler
