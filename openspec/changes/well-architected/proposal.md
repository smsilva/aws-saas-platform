# Proposal: Well-Architected Production Readiness

## Problem

The current lab is functional but has several gaps across the AWS Well-Architected Framework pillars that prevent it from being used as a reliable production foundation. Security hardening (SEC-002~006) and private control plane (VPN) are addressed in separate changes. This change covers all remaining P1, P2, and P3 items across Security, Reliability, Performance, Cost, Operational Excellence, and Sustainability pillars.

## Scope

This change tracks the full roadmap. Items are grouped by phase and pillar. Implementation happens incrementally — each item can be worked independently unless a prerequisite is noted.

### P0 — Prerequisites (Tracked Here, Not in Other Changes)

| Item | Pillar | Description |
|---|---|---|
| LAB-SEC-08 | Security | Enable EKS etcd encryption with KMS Customer Managed Key |

### P1 — Required Before Production Traffic

| Item | Pillar | Description |
|---|---|---|
| LAB-SEC-09 | Security | Create secrets in AWS Secrets Manager for `COGNITO_CLIENT_SECRET_*` and `STATE_JWT_SECRET` |
| LAB-SEC-10 | Security | Install External Secrets Operator; create `SecretStore` via IRSA |
| LAB-SEC-11 | Security | Replace `callback-handler-secret` manual K8s Secret with `ExternalSecret` |
| LAB-SEC-12 | Security | Add `PeerAuthentication mode: STRICT` to all tenant namespaces |
| LAB-OPS-01 | Ops | Migrate VPC, EKS, IAM, DynamoDB, WAF provisioning to Terraform |
| LAB-OPS-02 | Ops | Deploy ArgoCD for GitOps management of Kubernetes manifests |

### P2 — Required for Reliable Operation

| Item | Pillar | Description |
|---|---|---|
| LAB-REL-01 | Reliability | Install Karpenter for dynamic node provisioning with Spot/On-Demand mix |
| LAB-REL-02 | Reliability | Add `topologySpreadConstraints` to all service deployments |
| LAB-REL-03 | Reliability | Add `PodDisruptionBudget` (minAvailable: 1) to each critical service |
| LAB-REL-04 | Reliability | Verify `livenessProbe` and `readinessProbe` on all deployments |
| LAB-REL-05 | Reliability | Add Istio `outlierDetection` on discovery and callback-handler |
| LAB-OPS-03 | Ops | Split repo into `infra/` (Terraform) and `platform/` (ArgoCD) layers |
| LAB-OPS-04 | Ops | Send Istio and ALB access logs to CloudWatch Logs / S3 |
| LAB-OPS-05 | Ops | Enable EKS Control Plane Logging (API, authenticator, audit) |
| LAB-OPS-06 | Ops | Create CloudWatch Alarms for 5xx rate, p99 latency, unhealthy pods |
| LAB-PERF-01 | Performance | Deploy Prometheus + Grafana (`kube-prometheus-stack`) |
| LAB-PERF-02 | Performance | Add Jaeger or Tempo for distributed tracing |

### P3 — Optimization Phase

| Item | Pillar | Description |
|---|---|---|
| LAB-REL-06 | Reliability | Migrate `tenant-registry` to DynamoDB Global Table (add `eu-central-1` replica) |
| LAB-REL-07 | Reliability | Evaluate DAX if p99 latency on discovery exceeds 500ms |
| LAB-REL-08 | Reliability | Enable AWS Backup for DynamoDB (7-day PITR) |
| LAB-REL-09 | Reliability | Document and test RTO/RPO for single-region cluster loss |
| LAB-PERF-03 | Performance | Add per-tenant dashboards for discovery latency and DynamoDB cache hit rate |
| LAB-PERF-04 | Performance | Use Goldilocks (VPA recommender) for right-sizing pod requests/limits |
| LAB-COST-01 | Cost | Configure Karpenter NodePool with Spot for tenant workloads |
| LAB-COST-02 | Cost | Evaluate Savings Plans for NAT Gateway and always-on nodes |
| LAB-COST-03 | Cost | Document GA cost as fixed line item; schedule off-hours for dev environment |
| LAB-COST-04 | Cost | Tag all AWS resources with `tenant`, `environment`, `cluster`; enable Cost Allocation Tags |
| LAB-OPS-07 | Ops | Make tenant onboarding idempotent and versionable (candidate for `waspctl tenant create`) |
| LAB-OPS-08 | Ops | Document rollback runbook for Helm chart / ArgoCD application |
| LAB-OPS-09 | Ops | Build CI/CD pipeline (GitHub Actions) for Docker images → ECR |
| LAB-OPS-10 | Ops | Add Trivy or Grype scan before ECR push |
| LAB-SUS-01 | Sustainability | Configure Karpenter to prefer Graviton3 instances (`m7g`, `t4g`) |

## Relation to Other Changes

- **security-hardening**: covers SEC-002~006 — do not duplicate here
- **vpn-private-control-plane**: covers LAB-VPN-01~06 — do not duplicate here
- This change covers everything else in the roadmap
