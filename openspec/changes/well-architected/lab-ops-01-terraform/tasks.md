# Tasks: LAB-OPS-01 + LAB-OPS-03 — Terraform IaC + Repo Structure

## Checklist

### Repo Structure (LAB-OPS-03)
- [ ] Create `infra/` directory for Terraform modules
- [ ] Create `platform/` directory for Kubernetes manifests (ArgoCD source)

### Terraform Migration (LAB-OPS-01)
- [ ] Initialize Terraform workspace in `infra/`
- [ ] Migrate VPC (`01-create-vpc`) → Terraform using `terraform-aws-modules/vpc`
- [ ] Migrate EKS (`02-create-cluster`) → Terraform using `terraform-aws-modules/eks`
- [ ] Migrate IAM roles (ALB Controller, IRSA) → Terraform
- [ ] Migrate DynamoDB (`10-create-dynamodb`) → Terraform
- [ ] Migrate WAF (`09-configure-waf`, `15-configure-waf-ratelimit`) → Terraform
- [ ] Validate Terraform plan against existing infrastructure in staging
- [ ] Remove shell scripts after Terraform is validated
