# Tasks: Well-Architected Production Readiness

Items are organized by priority tier. Complete P0 before starting P1; P1 before P2; P2 before P3.

## P0 — Prerequisites

### LAB-SEC-08 — KMS Encryption for etcd
- [ ] Create KMS CMK in `us-east-1` for EKS secrets encryption
- [ ] Add `secretsEncryption.keyARN` to eksctl config in `scripts/02-create-cluster`
- [ ] For existing clusters: run `aws eks associate-encryption-config` to enable in place
- [ ] Verify: `kubectl get secret -n auth callback-handler-secret -o yaml` shows `kms` encryption provider

---

## P1 — Required Before Production Traffic

### LAB-SEC-09 — AWS Secrets Manager

- [ ] Create secret `wasp/lab/callback-handler/customer1` with `COGNITO_CLIENT_SECRET_CUSTOMER1`
- [ ] Create secret `wasp/lab/callback-handler/customer2` with `COGNITO_CLIENT_SECRET_CUSTOMER2`
- [ ] Create secret `wasp/lab/callback-handler/state-jwt-secret` with `STATE_JWT_SECRET`

### LAB-SEC-10 — External Secrets Operator

- [ ] Install ESO via Helm: `helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace`
- [ ] Create IAM role with `secretsmanager:GetSecretValue` on `wasp/lab/*`; attach via IRSA to ESO service account in `auth` namespace
- [ ] Create `SecretStore` resource in namespace `auth`

### LAB-SEC-11 — ExternalSecret for callback-handler

- [ ] Write `ExternalSecret` manifest replacing `callback-handler-secret`
- [ ] Deploy and verify: `kubectl get secret -n auth callback-handler-secret` contains all expected keys
- [ ] Test: restart `callback-handler` and confirm login flow works end-to-end
- [ ] Remove manual `kubectl apply` of the old secret from `scripts/13-deploy-services`

### LAB-SEC-12 — Istio mTLS Strict

- [ ] Add `PeerAuthentication mode: STRICT` to namespaces: `platform`, `auth`, `discovery`, `customer1`, `customer2`
- [ ] Verify no non-sidecar pods exist in those namespaces
- [ ] Test: internal service-to-service calls still succeed

### LAB-OPS-01 — Terraform IaC

- [ ] Initialize Terraform workspace in `infra/`
- [ ] Migrate VPC (`01-create-vpc`) → Terraform
- [ ] Migrate EKS (`02-create-cluster`) → Terraform
- [ ] Migrate IAM roles (ALB Controller, IRSA) → Terraform
- [ ] Migrate DynamoDB (`10-create-dynamodb`) → Terraform
- [ ] Migrate WAF (`09-configure-waf`, `15-configure-waf-ratelimit`) → Terraform

### LAB-OPS-02 — ArgoCD

- [ ] Install ArgoCD via Helm in namespace `argocd`
- [ ] Create ArgoCD Application for each namespace (platform, auth, discovery, customer1, customer2)
- [ ] Remove `kubectl apply` calls from `scripts/13-deploy-services` for manifests now managed by ArgoCD

---

## P2 — Reliable Operation

### LAB-REL-01~03 — Karpenter + PDB + TopologySpread

- [ ] Uninstall Cluster Autoscaler
- [ ] Install Karpenter via Helm
- [ ] Configure `NodePool` for platform/auth (On-Demand) and customer namespaces (Spot with fallback)
- [ ] Add `topologySpreadConstraints` to all service Deployments
- [ ] Add `PodDisruptionBudget` (minAvailable: 1) to all critical services

### LAB-REL-04~05 — Health Checks + Circuit Breaking

- [ ] Verify `livenessProbe` and `readinessProbe` are present in all Deployments
- [ ] Add Istio `DestinationRule` with `outlierDetection` for discovery and callback-handler

### LAB-OPS-04~06 — Logging + Alarms

- [ ] Enable ALB access logs to S3 via annotation `alb.ingress.kubernetes.io/load-balancer-attributes`
- [ ] Enable EKS Control Plane Logging: API, authenticator, audit, scheduler, controller manager
- [ ] Create CloudWatch Alarm: ALB 5xx rate > 1%
- [ ] Create CloudWatch Alarm: ALB p99 latency > 2s
- [ ] Create CloudWatch Alarm: unhealthy pod count > 0

### LAB-PERF-01~02 — Prometheus + Tracing

- [ ] Install `kube-prometheus-stack` via Helm
- [ ] Expose Grafana at `monitoring.wasp.silvios.me` (restricted to VPN)
- [ ] Configure Istio tracing with Tempo backend
- [ ] Create basic service latency dashboard for discovery and callback-handler

---

## P3 — Optimization

### LAB-REL-06~09 — DynamoDB Global Tables + Backup

- [ ] Convert `tenant-registry` to DynamoDB Global Table; add `eu-central-1` replica
- [ ] Enable AWS Backup plan for DynamoDB with 7-day PITR
- [ ] Document RTO/RPO for single-region cluster loss

### LAB-COST-04 — Resource Tagging

- [ ] Tag all AWS resources with `tenant`, `environment`, `cluster`
- [ ] Enable Cost Allocation Tags in AWS Billing Console

### LAB-OPS-09~10 — CI/CD + Image Scanning

- [ ] Create `.github/workflows/build.yml` for building and pushing to ECR
- [ ] Add Trivy scan step — fail on CRITICAL vulnerabilities
- [ ] Migrate Docker Hub references to ECR

### LAB-SUS-01 — Graviton3 Nodes

- [ ] Update Karpenter `NodePool` to prefer `m7g`, `t4g` instance families

---

## Tracking

Update `docs/well-architected-production-roadmap.md` as each item is completed, changing the priority indicator from open to done.
