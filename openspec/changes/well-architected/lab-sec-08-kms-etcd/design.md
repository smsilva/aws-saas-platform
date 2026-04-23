# Design: LAB-SEC-08 — KMS Encryption for etcd

Add `secretsEncryption.keyARN` to the eksctl cluster config:

```yaml
secretsEncryption:
  keyARN: arn:aws:kms:us-east-1:221047292361:key/<key-id>
```

This is a prerequisite for LAB-SEC-09~11 (Secrets Manager + ESO) because ExternalSecret resources are stored in etcd.

> Enabling encryption on an existing cluster re-encrypts all secrets in place — this is an online operation but takes a few minutes proportional to the number of secrets.
