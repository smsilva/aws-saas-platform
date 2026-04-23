# Design: LAB-COST-02~04 — Resource Tagging, Savings Plans, and Cost Visibility

## Tagging strategy

Standard tags applied to all resources:

| Tag | Values |
|---|---|
| `environment` | `lab`, `staging`, `prod` |
| `cluster` | `wasp-lab` |
| `tenant` | `platform`, `customer1`, `customer2` |

Apply tags via Terraform (default_tags on provider) and Karpenter NodePool labels for EC2 instances.

## Off-hours schedule

Use EventBridge Scheduler to scale EKS node groups to 0 outside business hours in dev. Alternatively, configure Karpenter to scale down via a `ConsolidationPolicy`.

## Savings Plans

Evaluate after 3 months of usage data. Compute Savings Plans provide the most flexibility (not instance-family-locked). NAT Gateway usage is typically covered by Data Transfer commitment rather than Savings Plans.
