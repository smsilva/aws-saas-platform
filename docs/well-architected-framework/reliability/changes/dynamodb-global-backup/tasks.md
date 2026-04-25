# Tasks: LAB-REL-06~09 — DynamoDB Global Tables and Backup

## Checklist

### Global Tables (LAB-REL-06)
- [ ] Convert `tenant-registry` to DynamoDB Global Table
- [ ] Add `eu-central-1` replica

### DAX Evaluation (LAB-REL-07, conditional)
- [ ] After observability is in place: check p99 latency on `discovery`
- [ ] If p99 > 500ms: evaluate DAX cluster for `tenant-registry`

### Backup (LAB-REL-08)
- [ ] Enable AWS Backup plan for DynamoDB with 7-day PITR

### RTO/RPO (LAB-REL-09)
- [ ] Document RTO/RPO targets for single-region cluster loss
- [ ] Run a failover drill: disable `us-east-1` traffic, verify `eu-central-1` serves requests
