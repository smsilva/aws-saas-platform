# Design: LAB-OPS-01 + LAB-OPS-03 — Terraform IaC + Repo Structure

## Repo structure

```
infra/          # Terraform — AWS resources
  vpc/
  eks/
  iam/
  dynamodb/
  waf/
platform/       # ArgoCD source — Kubernetes manifests
  auth/
  discovery/
  customer1/
  customer2/
```

Shell scripts `01–15` are kept as reference until Terraform state is validated in staging, then removed.

## Migration order

VPC → IAM roles → EKS → DynamoDB → Cognito → WAF

Use `terraform-aws-modules/eks` and `terraform-aws-modules/vpc` as base modules. Import existing resources into state with `terraform import` to avoid re-provisioning.
