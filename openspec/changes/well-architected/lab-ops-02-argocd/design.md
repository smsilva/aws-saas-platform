# Design: LAB-OPS-02 — ArgoCD GitOps

Install ArgoCD via Helm. Each namespace becomes an `Application` pointing to the corresponding path in `platform/`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: auth
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<org>/aws-saas-platform
    targetRevision: main
    path: platform/auth
  destination:
    server: https://kubernetes.default.svc
    namespace: auth
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Image updates are handled via ArgoCD Image Updater or a GitHub Actions push that updates the image digest in the manifest before ArgoCD syncs.
