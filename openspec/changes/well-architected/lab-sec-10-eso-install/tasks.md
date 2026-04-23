# Tasks: LAB-SEC-10 — External Secrets Operator

## Checklist

- [ ] Install ESO via Helm: `helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace`
- [ ] Create IAM role with `secretsmanager:GetSecretValue` on `wasp/lab/*`; attach via IRSA to ESO service account in `auth` namespace
- [ ] Create `SecretStore` resource in namespace `auth`
