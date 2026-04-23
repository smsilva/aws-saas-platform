# Well-Architected Production Readiness

Each subdirectory is a self-contained spec (`proposal.md`, `tasks.md`, `design.md`).

## Execution order

```
P0  lab-sec-08-kms-etcd/
P1  lab-sec-09-secrets-manager/       (requires P0)
P1  lab-sec-10-eso-install/           (requires lab-sec-09)
P1  lab-sec-11-external-secret/       (requires lab-sec-10)
P1  lab-sec-12-mtls-strict/
P1  lab-ops-01-terraform/
P1  lab-ops-02-argocd/                (requires lab-ops-01)
P2  lab-rel-01-03-karpenter-pdb/
P2  lab-rel-04-05-health-checks/
P2  lab-ops-04-06-logging-alarms/
P2  lab-perf-01-02-observability/
P3  lab-rel-06-09-dynamodb-backup/
P3  lab-cost-02-04-tagging-savings/
P3  lab-ops-07-10-cicd-runbooks/
P3  lab-sus-01-graviton/              (requires lab-rel-01-03)
```

## Original files

The files `proposal.md`, `tasks.md`, and `design.md` at this level are the original monolithic spec kept for reference.