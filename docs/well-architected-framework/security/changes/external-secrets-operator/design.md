# Design: LAB-SEC-10 — External Secrets Operator

Install ESO via Helm from `external-secrets/external-secrets`. Create an IAM role with `secretsmanager:GetSecretValue` scoped to `wasp/lab/*` and attach it via IRSA annotation on the ESO service account in namespace `auth`.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: auth
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
```
