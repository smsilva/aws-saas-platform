# Design: LAB-SEC-11 — ExternalSecret for callback-handler

Replace the manually managed `callback-handler-secret` with an `ExternalSecret` that syncs all keys from Secrets Manager:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: callback-handler-secret
  namespace: auth
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: callback-handler-secret
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: wasp/lab/callback-handler/customer1
    - extract:
        key: wasp/lab/callback-handler/customer2
    - extract:
        key: wasp/lab/callback-handler/state-jwt-secret
```
