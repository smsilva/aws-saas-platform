# Design: LAB-PERF-01~04 — Metrics, Tracing, and Dashboards

Install `kube-prometheus-stack` via Helm. Expose Grafana at `monitoring.wasp.silvios.me` — internal only via Istio `AuthorizationPolicy` restricting source principals to the VPN IP range.

For tracing, configure Istio with `meshConfig.defaultConfig.tracing.zipkin.address` pointing to a Tempo instance. Tempo stores traces in S3.

```yaml
meshConfig:
  defaultConfig:
    tracing:
      zipkin:
        address: tempo.monitoring:9411
```

Goldilocks runs the VPA in recommendation mode only (no auto-apply). Review dashboard for over/under-provisioned pods and update manifest requests/limits manually.
