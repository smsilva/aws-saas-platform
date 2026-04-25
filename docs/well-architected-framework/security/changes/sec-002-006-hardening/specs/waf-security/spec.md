# Spec Delta: waf-security

## MODIFIED Requirements

### Requirement: Open Security Issues Tracked

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

### Requirement: IAM Policy Integrity Verification

The system SHALL verify the SHA256 hash of any IAM policy file downloaded from an external URL before applying it to the AWS account. A hash mismatch SHALL cause the provisioning script to exit non-zero without creating or updating any IAM policy.

### Requirement: Container Image Digest Pinning

The system SHALL reference all container images in provisioning scripts using a fixed SHA256 digest. Floating tags (`:latest` or version tags without digest) SHALL NOT be used in production or lab scripts.

### Requirement: ALB Inbound Restricted to Global Accelerator

The system SHALL restrict ALB Security Group inbound rules to the Global Accelerator edge IP ranges (`35.191.0.0/16`, `130.211.0.0/22`). Direct HTTP/HTTPS access to the ALB bypassing Global Accelerator SHALL be blocked.

### Requirement: IMDSv2 Mandatory on All Nodes

The system SHALL configure all EKS managed node groups with `httpTokens: required` and `httpPutResponseHopLimit: 1`, preventing any pod from accessing the instance metadata service without an IMDSv2 session token.
