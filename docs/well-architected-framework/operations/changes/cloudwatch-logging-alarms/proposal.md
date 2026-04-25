# Proposal: LAB-OPS-04~06 — Logging and CloudWatch Alarms

## Problem

ALB access logs and EKS control plane logs are not enabled, making incident investigation dependent on memory or cluster-level kubectl access. There are no proactive alarms — failures are discovered by users, not by operators.

## Scope

Enable ALB access logs to S3, enable EKS Control Plane Logging (API, authenticator, audit, scheduler, controller manager), and create CloudWatch Alarms for 5xx rate, p99 latency, and unhealthy pod count.

### Items Covered

- **LAB-OPS-04**: ALB access logs → S3
- **LAB-OPS-05**: EKS Control Plane Logging
- **LAB-OPS-06**: CloudWatch Alarms (5xx, p99, unhealthy pods)
