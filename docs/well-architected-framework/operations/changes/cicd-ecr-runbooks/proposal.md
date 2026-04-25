# Proposal: LAB-OPS-07~10 — CI/CD, Image Scanning, and Runbooks

## Problem

Docker images are built and pushed manually. There is no vulnerability scanning before ECR push. Tenant onboarding is not idempotent — re-running scripts may produce inconsistent state. There is no rollback runbook for failed Helm/ArgoCD deployments.

## Scope

Build a GitHub Actions pipeline for building, scanning, and pushing images to ECR. Make tenant onboarding idempotent. Document rollback procedures for Helm and ArgoCD.

### Items Covered

- **LAB-OPS-07**: Idempotent tenant onboarding (candidate for `waspctl tenant create`)
- **LAB-OPS-08**: Rollback runbook for Helm chart / ArgoCD application
- **LAB-OPS-09**: GitHub Actions CI/CD pipeline (build → Trivy scan → ECR push)
- **LAB-OPS-10**: Trivy scan — fail on CRITICAL vulnerabilities
