# Design: LAB-REL-06~09 — DynamoDB Global Tables and Backup

## Global Tables

Convert `tenant-registry` to a Global Table via `aws dynamodb create-global-table` (or Terraform `aws_dynamodb_table` with `replica` block). The `eu-central-1` replica is read/write — the discovery service can be pointed at the nearest region.

## DAX (LAB-REL-07, conditional)

Only evaluate after LAB-PERF-01 (Prometheus) provides p99 data. If p99 > 500ms on discovery, add a DAX cluster in front of `tenant-registry`. Otherwise, skip — DAX adds operational complexity.

## AWS Backup

7-day PITR via AWS Backup plan. Configure a backup vault in both regions. Backup plan runs daily with 7-day retention.