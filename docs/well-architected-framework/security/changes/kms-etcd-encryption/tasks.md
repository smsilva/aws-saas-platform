# Tasks: LAB-SEC-08 — KMS Encryption for etcd

## Checklist

- [ ] Create KMS CMK in `us-east-1` for EKS secrets encryption
- [ ] Add `secretsEncryption.keyARN` to eksctl config in `scripts/02-create-cluster`
- [ ] For existing clusters: run `aws eks associate-encryption-config` to enable in place
- [ ] Verify: `kubectl get secret -n auth callback-handler-secret -o yaml` shows `kms` encryption provider
