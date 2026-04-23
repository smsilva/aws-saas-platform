# Design: LAB-REL-04~05 — Health Probes and Circuit Breaking

## Outlier detection (circuit breaking)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: discovery
  namespace: discovery
spec:
  host: discovery
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
```

Apply the same pattern for `callback-handler` in namespace `auth`.

## Probe baseline

Each Deployment should have at minimum:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```
