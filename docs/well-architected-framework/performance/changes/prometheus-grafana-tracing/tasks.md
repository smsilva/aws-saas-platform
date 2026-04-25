# Tasks: LAB-PERF-01~04 — Metrics, Tracing, and Dashboards

## Checklist

### Prometheus + Grafana (LAB-PERF-01)
- [ ] Install `kube-prometheus-stack` via Helm
- [ ] Expose Grafana at `monitoring.wasp.silvios.me` (restricted to VPN via Istio `AuthorizationPolicy`)

### Distributed Tracing (LAB-PERF-02)
- [ ] Configure Istio tracing with Tempo backend
- [ ] Create basic service latency dashboard for `discovery` and `callback-handler`

### Per-tenant Dashboards (LAB-PERF-03)
- [ ] Add per-tenant dashboard for discovery latency
- [ ] Add per-tenant dashboard for DynamoDB cache hit rate

### Right-sizing (LAB-PERF-04)
- [ ] Install Goldilocks (VPA recommender)
- [ ] Review recommendations and update pod requests/limits
