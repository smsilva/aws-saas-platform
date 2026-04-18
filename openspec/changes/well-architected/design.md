# Design: Well-Architected Production Readiness

This document captures architectural decisions for the items in this change. Each section corresponds to a group of related tasks.

## LAB-SEC-08 — KMS Encryption for etcd

Add `secretsEncryption.keyARN` to the eksctl cluster config. A KMS CMK must be created before cluster provisioning (or before enabling encryption on an existing cluster).

```yaml
secretsEncryption:
  keyARN: arn:aws:kms:us-east-1:221047292361:key/<key-id>
```

This is a prerequisite for LAB-SEC-09~11 (Secrets Manager + ESO) because those secrets are ultimately stored in etcd as ExternalSecret resources.

> Enabling encryption on an existing cluster re-encrypts all secrets in place — this is an online operation but takes a few minutes proportional to the number of secrets.

## LAB-SEC-09~11 — External Secrets Operator

Replace the manually managed `callback-handler-secret` with AWS Secrets Manager + ESO:

1. Create one secret in Secrets Manager per tenant: `wasp/<env>/callback-handler/<tenant-id>` containing the App Client secret.
2. Create `STATE_JWT_SECRET` in Secrets Manager: `wasp/<env>/callback-handler/state-jwt-secret`.
3. Install ESO via Helm: `external-secrets/external-secrets`.
4. Create `SecretStore` in namespace `auth` with IRSA annotation on the service account.
5. Replace the `Secret` manifest for `callback-handler-secret` with an `ExternalSecret` that syncs all keys.

**Benefit:** Adding a new tenant requires only adding a new secret in Secrets Manager — no manual `kubectl apply` and no `callback-handler` rollout restart.

## LAB-SEC-12 — Istio mTLS Strict Mode

Add `PeerAuthentication` to each tenant namespace:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: customer1
spec:
  mtls:
    mode: STRICT
```

This blocks all non-mTLS traffic between pods, enforcing zero-trust within the mesh. Apply after confirming all pods in the namespace have Istio sidecars.

## LAB-OPS-01~02 — Terraform + ArgoCD

**IaC migration:** Use `terraform-aws-modules/eks` and `terraform-aws-modules/vpc` as base modules. Migration order: VPC → IAM roles → EKS → DynamoDB → Cognito → WAF. Scripts `01–15` become Terraform resources and are kept as reference until Terraform is validated.

**GitOps:** ArgoCD manages the `platform/` layer. Each namespace (platform, auth, discovery, customer*) becomes an ArgoCD Application pointing to a path in the repo. Image updates are handled via ArgoCD Image Updater or a GitHub Actions push to the manifest repo.

## LAB-REL-01~05 — Reliability Baseline

**Karpenter:** replaces Cluster Autoscaler. Install via Helm. Configure a `NodePool` with `m7i.large` On-Demand for platform/auth namespaces and `m7i.large` Spot for customer namespaces (with `karpenter.sh/capacity-type: spot` toleration).

**TopologySpread + PDB:** Add to each Deployment manifest:

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

## LAB-PERF-01~02 — Observability

Install `kube-prometheus-stack` via Helm. Expose Grafana at `monitoring.wasp.silvios.me` (internal only via Istio `AuthorizationPolicy` restricting to VPN IP range).

For tracing, configure Istio with `meshConfig.defaultConfig.tracing.zipkin.address` pointing to a Tempo instance. Tempo stores traces in S3.

## LAB-OPS-09~10 — CI/CD for Container Images

GitHub Actions workflow (`.github/workflows/build.yml`) triggered on push to `main`:
1. Build each service image with `--platform linux/amd64`
2. Push to ECR private registry (replace Docker Hub)
3. Run Trivy scan — fail if CRITICAL vulnerabilities found
4. Update the image digest in the K8s manifest (or ArgoCD Image Updater handles this)
