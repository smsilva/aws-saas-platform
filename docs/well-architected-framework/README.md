# Well-Architected Framework — Production Roadmap

17 changes across 6 AWS WAF pillars, ordered by execution priority.
P0 unblocks everything; higher priorities have sequential dependencies within each track.

## P0 — Foundation

| Pillar | Lab IDs | Change | Description |
|---|---|---|---|
| 🔐 Security | [LAB-VPN-01~06](security/changes/vpn-private-control-plane/tasks.md) | [VPN — Private Control Plane](security/changes/vpn-private-control-plane/proposal.md) | Private EKS API endpoint via WireGuard — removes internet-facing control plane |
| 🔐 Security | [SEC-002~006](security/changes/sec-002-006-hardening/tasks.md) | [Security Hardening](security/changes/sec-002-006-hardening/proposal.md) | Fix 5 open issues: IAM policy hash, image digest, cluster-admin RBAC, ALB SGs, IMDSv2 |
| 🔐 Security | [LAB-SEC-08](security/changes/kms-etcd-encryption/tasks.md) | [KMS etcd Encryption](security/changes/kms-etcd-encryption/proposal.md) | Envelope-encrypt Kubernetes Secrets at rest with a KMS Customer Managed Key |

## P1 — Requires P0

| Pillar | Lab IDs | Change | Description |
|---|---|---|---|
| 🔐 Security | [LAB-SEC-09](security/changes/secrets-manager/tasks.md) | [Secrets Manager](security/changes/secrets-manager/proposal.md) | Move Cognito and JWT secrets to AWS Secrets Manager with rotation policy |
| 🔐 Security | [LAB-SEC-10](security/changes/external-secrets-operator/tasks.md) | [External Secrets Operator](security/changes/external-secrets-operator/proposal.md) | Auto-sync Secrets Manager entries into Kubernetes Secrets via ESO |
| 🔐 Security | [LAB-SEC-11](security/changes/callback-handler-external-secret/tasks.md) | [ExternalSecret for callback-handler](security/changes/callback-handler-external-secret/proposal.md) | Wire callback-handler to ESO — removes manual secret patching on tenant onboarding |
| 🔐 Security | [LAB-SEC-12](security/changes/istio-mtls-strict/tasks.md) | [Istio mTLS Strict Mode](security/changes/istio-mtls-strict/proposal.md) | Enable STRICT mTLS — encrypts all pod-to-pod traffic in the mesh |
| 🔧 Operations | [LAB-OPS-01+03](operations/changes/terraform-iac/tasks.md) | [Terraform IaC](operations/changes/terraform-iac/proposal.md) | Replace shell scripts with Terraform — state tracking, drift detection, plan/apply |
| 🔧 Operations | [LAB-OPS-02](operations/changes/argocd-gitops/tasks.md) | [ArgoCD GitOps](operations/changes/argocd-gitops/proposal.md) | Replace `kubectl apply` scripts with ArgoCD — GitOps reconciliation and audit trail |

## P2 — Requires P1

| Pillar | Lab IDs | Change | Description |
|---|---|---|---|
| 🏛 Reliability | [LAB-REL-01~03, LAB-COST-01](reliability/changes/karpenter-pdb-topology/tasks.md) | [Karpenter, PDB, Topology Spread](reliability/changes/karpenter-pdb-topology/proposal.md) | Karpenter + PDB + topology spread — AZ resilience and spot/on-demand cost split |
| 🏛 Reliability | [LAB-REL-04~05](reliability/changes/health-probes-circuit-breaking/tasks.md) | [Health Probes and Circuit Breaking](reliability/changes/health-probes-circuit-breaking/proposal.md) | Add liveness/readiness probes and Istio circuit-breaking to all services |
| 🔧 Operations | [LAB-OPS-04~06](operations/changes/cloudwatch-logging-alarms/tasks.md) | [CloudWatch Logging and Alarms](operations/changes/cloudwatch-logging-alarms/proposal.md) | Enable ALB + EKS control plane logs and proactive CloudWatch alarms |
| ⚡ Performance | [LAB-PERF-01~04](performance/changes/prometheus-grafana-tracing/tasks.md) | [Prometheus, Grafana, Tracing](performance/changes/prometheus-grafana-tracing/proposal.md) | In-cluster metrics, distributed tracing, and resource utilization dashboards |

## P3 — Requires P2

| Pillar | Lab IDs | Change | Description |
|---|---|---|---|
| 🏛 Reliability | [LAB-REL-06~09](reliability/changes/dynamodb-global-backup/tasks.md) | [DynamoDB Global Tables and Backup](reliability/changes/dynamodb-global-backup/proposal.md) | Multi-region `tenant-registry` with Global Tables and automated point-in-time backups |
| 💰 Cost | [LAB-COST-02~04](cost/changes/tagging-savings-plans/tasks.md) | [Tagging and Savings Plans](cost/changes/tagging-savings-plans/proposal.md) | Consistent resource tagging, cost allocation by tenant, and Savings Plans evaluation |
| 🔧 Operations | [LAB-OPS-07~10](operations/changes/cicd-ecr-runbooks/tasks.md) | [CI/CD and Runbooks](operations/changes/cicd-ecr-runbooks/proposal.md) | CI/CD pipeline, ECR image scanning, idempotent onboarding, rollback runbooks |
| 🌱 Sustainability | [LAB-SUS-01](sustainability/changes/graviton3-nodes/tasks.md) | [Graviton3 Nodes](sustainability/changes/graviton3-nodes/proposal.md) | Graviton3 Karpenter NodePool preference — better price/performance and lower energy use |
