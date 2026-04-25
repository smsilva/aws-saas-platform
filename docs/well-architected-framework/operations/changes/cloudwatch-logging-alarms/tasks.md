# Tasks: LAB-OPS-04~06 — Logging and CloudWatch Alarms

## Checklist

### ALB Access Logs (LAB-OPS-04)
- [ ] Enable ALB access logs to S3 via annotation `alb.ingress.kubernetes.io/load-balancer-attributes: access_logs.s3.enabled=true,access_logs.s3.bucket=<bucket>`

### EKS Control Plane Logging (LAB-OPS-05)
- [ ] Enable EKS Control Plane Logging: API, authenticator, audit, scheduler, controller manager

### CloudWatch Alarms (LAB-OPS-06)
- [ ] Create CloudWatch Alarm: ALB 5xx rate > 1%
- [ ] Create CloudWatch Alarm: ALB p99 latency > 2s
- [ ] Create CloudWatch Alarm: unhealthy pod count > 0
