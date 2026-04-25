# Tasks: LAB-OPS-02 — ArgoCD GitOps

## Checklist

- [ ] Install ArgoCD via Helm in namespace `argocd`
- [ ] Create ArgoCD Application for namespace `platform`
- [ ] Create ArgoCD Application for namespace `auth`
- [ ] Create ArgoCD Application for namespace `discovery`
- [ ] Create ArgoCD Application for namespace `customer1`
- [ ] Create ArgoCD Application for namespace `customer2`
- [ ] Remove `kubectl apply` calls from `scripts/13-deploy-services` for manifests now managed by ArgoCD
