# Proposal: LAB-COST-02~04 — Resource Tagging, Savings Plans, and Cost Visibility

## Problem

AWS resources have no consistent tagging, making it impossible to break down costs by tenant, environment, or cluster in the AWS Billing Console. There is no regular cost review cadence and no dev environment off-hours schedule. Savings Plans for predictable workloads have not been evaluated.

## Scope

Tag all AWS resources with `tenant`, `environment`, and `cluster`. Enable Cost Allocation Tags. Document the GA cost as a fixed line item. Schedule off-hours shutdown for the dev environment. Evaluate Savings Plans for NAT Gateway and always-on nodes.

### Items Covered

- **LAB-COST-02**: Evaluate Savings Plans for NAT Gateway and always-on nodes
- **LAB-COST-03**: Document GA cost; schedule off-hours for dev environment
- **LAB-COST-04**: Tag all resources; enable Cost Allocation Tags
