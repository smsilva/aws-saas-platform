# Proposal: LAB-REL-06~09 — DynamoDB Global Tables and Backup

## Problem

`tenant-registry` is a single-region DynamoDB table. A regional AWS outage would make the discovery service unavailable. There is no automated backup policy. RTO/RPO targets are undefined.

## Scope

Convert `tenant-registry` to a DynamoDB Global Table with an `eu-central-1` replica. Enable AWS Backup with 7-day PITR. Document and test the RTO/RPO for single-region cluster loss. Evaluate DAX if p99 latency on discovery exceeds 500ms.

### Items Covered

- **LAB-REL-06**: DynamoDB Global Table with `eu-central-1` replica
- **LAB-REL-07**: DAX evaluation (conditional on latency data)
- **LAB-REL-08**: AWS Backup plan (7-day PITR)
- **LAB-REL-09**: RTO/RPO documentation and test
