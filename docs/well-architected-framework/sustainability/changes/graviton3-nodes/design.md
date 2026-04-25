# Design: LAB-SUS-01 — Graviton3 Node Preference

Update Karpenter `NodePool` `spec.template.spec.requirements` to list Graviton3 families first:

```yaml
requirements:
  - key: karpenter.k8s.aws/instance-family
    operator: In
    values: ["m7g", "t4g", "m7i", "t3"]  # Graviton preferred, x86 as fallback
  - key: kubernetes.io/arch
    operator: In
    values: ["arm64", "amd64"]
```

Images must be built with `--platform linux/arm64,linux/amd64` (multi-arch) or the CI workflow must build separate arm64 images. Update `.github/workflows/build.yml` to use `docker buildx` with multi-arch push.