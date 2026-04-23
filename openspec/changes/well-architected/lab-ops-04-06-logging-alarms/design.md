# Design: LAB-OPS-04~06 — Logging and CloudWatch Alarms

## ALB access logs

Enable via Ingress annotation:

```yaml
alb.ingress.kubernetes.io/load-balancer-attributes: >-
  access_logs.s3.enabled=true,
  access_logs.s3.bucket=wasp-lab-alb-logs,
  access_logs.s3.prefix=alb
```

## EKS Control Plane Logging

Enable via `aws eks update-cluster-config` or Terraform `enabled_cluster_log_types`:

```
["api", "audit", "authenticator", "controllerManager", "scheduler"]
```

## CloudWatch Alarms

Three alarms based on ALB and Container Insights metrics:

- `HTTPCode_ELB_5XX_Count` / `RequestCount` > 1% over 5 minutes
- `TargetResponseTime` p99 > 2000ms over 5 minutes
- Container Insights `pod_status_not_ready` > 0 over 1 minute
