# Design: LAB-SEC-12 — Istio mTLS Strict Mode

Add a `PeerAuthentication` resource to each namespace:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: customer1   # repeat for platform, auth, discovery, customer2
spec:
  mtls:
    mode: STRICT
```

This blocks all non-mTLS traffic between pods, enforcing zero-trust within the mesh. Apply only after confirming all pods in the namespace have Istio sidecars injected — a pod without a sidecar will fail to communicate after this change.
