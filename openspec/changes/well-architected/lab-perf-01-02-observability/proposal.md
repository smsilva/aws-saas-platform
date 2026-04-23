# Proposal: LAB-PERF-01~04 — Metrics, Tracing, and Dashboards

## Problem

There is no in-cluster metrics collection or distributed tracing. Debugging latency issues requires manual log scraping. Resource sizing for pods is based on guesswork rather than observed utilization.

## Scope

Install `kube-prometheus-stack` (Prometheus + Grafana) and configure Istio distributed tracing with Tempo. Create service latency dashboards. Use Goldilocks (VPA recommender) to inform right-sizing of pod requests/limits. Expose Grafana on the internal VPN domain.

### Items Covered

- **LAB-PERF-01**: `kube-prometheus-stack` (Prometheus + Grafana)
- **LAB-PERF-02**: Distributed tracing with Jaeger or Tempo
- **LAB-PERF-03**: Per-tenant dashboards for discovery latency and DynamoDB cache hit rate
- **LAB-PERF-04**: Goldilocks (VPA recommender) for pod right-sizing
