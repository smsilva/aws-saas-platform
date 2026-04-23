# Proposal: LAB-OPS-01 + LAB-OPS-03 — Terraform IaC + Repo Structure

## Problem

All infrastructure is provisioned via numbered shell scripts (`01-create-vpc`, `02-create-cluster`, etc.). This approach has no state tracking, no drift detection, no plan/apply workflow, and no idempotency guarantee. The repo has no clear boundary between infrastructure and platform concerns.

## Scope

Migrate VPC, EKS, IAM, DynamoDB, and WAF provisioning to Terraform. Split the repository into an `infra/` layer (Terraform) and a `platform/` layer (ArgoCD manifests). Shell scripts are kept as reference until Terraform is validated in staging.

### Items Covered

- **LAB-OPS-01**: Terraform migration of all AWS resources
- **LAB-OPS-03**: Repo split into `infra/` (Terraform) and `platform/` (ArgoCD)

## Relation to Other Changes

- **Required by**: LAB-OPS-02 (ArgoCD manages the `platform/` layer created here)
