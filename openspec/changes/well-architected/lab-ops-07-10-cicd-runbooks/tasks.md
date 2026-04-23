# Tasks: LAB-OPS-07~10 — CI/CD, Image Scanning, and Runbooks

## Checklist

### Idempotent onboarding (LAB-OPS-07)
- [ ] Audit `scripts/13-deploy-services` and tenant-specific scripts for non-idempotent operations
- [ ] Refactor or wrap in a `waspctl tenant create` command that is safe to re-run

### Rollback runbook (LAB-OPS-08)
- [ ] Document rollback procedure for a Helm chart upgrade
- [ ] Document rollback procedure for an ArgoCD application sync

### CI/CD pipeline (LAB-OPS-09)
- [ ] Create `.github/workflows/build.yml` triggered on push to `main`
- [ ] Build each service image with `--platform linux/amd64`
- [ ] Push to ECR private registry (replace Docker Hub)
- [ ] Update image digest in K8s manifest (or configure ArgoCD Image Updater)

### Image scanning (LAB-OPS-10)
- [ ] Add Trivy scan step in CI before ECR push
- [ ] Fail workflow on CRITICAL vulnerabilities
- [ ] Migrate Docker Hub references to ECR