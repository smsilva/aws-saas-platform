# Spec Delta: waf-security

## MODIFIED Requirements

### Open Security Issues Tracked

MODIFIED — update status of SEC-002, SEC-003, SEC-005, SEC-006 to Resolved after this change is applied.

The following issues remain open until remediated by this change:

| ID | Severity | Status after this change |
|---|---|---|
| SEC-002 | Medium | Resolved |
| SEC-003 | Low | Resolved |
| SEC-004 | Medium | Documented (Lab-Only Intentional) |
| SEC-005 | Low | Resolved |
| SEC-006 | Medium | Resolved |

## ADDED Requirements

### IAM Policy Integrity Verification

Before applying any IAM policy downloaded from an external URL, the provisioning script verifies its SHA256 hash. A hash mismatch causes the script to exit non-zero without creating or updating any IAM policy.

### Container Image Digest Pinning

All container images referenced in provisioning scripts use a fixed SHA256 digest. Floating tags (`:latest` or version tags without digest) are never used in production or lab scripts.

### ALB Inbound Restricted to Global Accelerator

ALB Security Group inbound rules are restricted to the Global Accelerator edge IP ranges (`35.191.0.0/16`, `130.211.0.0/22`). Direct HTTP/HTTPS access to the ALB bypassing Global Accelerator is blocked.

### IMDSv2 Mandatory on All Nodes

All EKS managed node groups are configured with `httpTokens: required` and `httpPutResponseHopLimit: 1`, preventing any pod from accessing the instance metadata service without an IMDSv2 session token.