# Well-Architected Framework — Production Roadmap

Each subdirectory is a self-contained change with `proposal.md`, `tasks.md`, and `design.md`.

## Execution order

```
P0  security/changes/vpn-private-control-plane/        (LAB-VPN-01~06)
P0  security/changes/sec-002-006-hardening/            (SEC-002~006)
P0  security/changes/kms-etcd-encryption/              (LAB-SEC-08)

P1  security/changes/secrets-manager/                  (LAB-SEC-09, requires P0)
P1  security/changes/external-secrets-operator/        (LAB-SEC-10, requires secrets-manager)
P1  security/changes/callback-handler-external-secret/ (LAB-SEC-11, requires eso-install)
P1  security/changes/istio-mtls-strict/                (LAB-SEC-12)
P1  operations/changes/terraform-iac/                  (LAB-OPS-01+03)
P1  operations/changes/argocd-gitops/                  (LAB-OPS-02, requires terraform-iac)

P2  reliability/changes/karpenter-pdb-topology/        (LAB-REL-01~03 + LAB-COST-01)
P2  reliability/changes/health-probes-circuit-breaking/(LAB-REL-04~05)
P2  operations/changes/cloudwatch-logging-alarms/      (LAB-OPS-04~06)
P2  performance/changes/prometheus-grafana-tracing/    (LAB-PERF-01~04)

P3  reliability/changes/dynamodb-global-backup/        (LAB-REL-06~09)
P3  cost/changes/tagging-savings-plans/                (LAB-COST-02~04)
P3  operations/changes/cicd-ecr-runbooks/              (LAB-OPS-07~10)
P3  sustainability/changes/graviton3-nodes/            (LAB-SUS-01, requires karpenter)
```

## Pillars

| Pillar | Directory | Changes |
|---|---|---|
| 🔐 Security | `security/changes/` | 7 |
| 🏛 Reliability | `reliability/changes/` | 3 |
| ⚡ Performance | `performance/changes/` | 1 |
| 💰 Cost | `cost/changes/` | 1 |
| 🔧 Operations | `operations/changes/` | 4 |
| 🌱 Sustainability | `sustainability/changes/` | 1 |