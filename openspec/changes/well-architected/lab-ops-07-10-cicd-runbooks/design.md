# Design: LAB-OPS-07~10 — CI/CD, Image Scanning, and Runbooks

## GitHub Actions workflow

`.github/workflows/build.yml` triggered on push to `main`:

1. Build each service image with `--platform linux/amd64`
2. Run Trivy scan — fail if CRITICAL vulnerabilities found
3. Push to ECR private registry
4. Update the image digest in the K8s manifest (ArgoCD Image Updater picks it up on next sync)

## Trivy scan

```yaml
- name: Trivy scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.ECR_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    exit-code: 1
    severity: CRITICAL
```

## Rollback (LAB-OPS-08)

**Helm:** `helm rollback <release> <revision> -n <namespace>`

**ArgoCD:** Set the Application `targetRevision` back to the previous commit SHA and sync. Use `argocd app rollback <app> <history-id>` for a single-command rollback.