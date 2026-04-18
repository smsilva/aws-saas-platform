# WAF Security

## Purpose

Define the behavioral contracts for the WAFv2 WebACL protecting the platform ALB, including managed rule sets, rate limiting, and the open security issues requiring remediation.

## Requirements

### Requirement: Managed Rule Sets

The system SHALL apply the following AWS Managed Rules on the WebACL associated with the ALB, evaluated in this order:

1. `AWSManagedRulesCommonRuleSet` — blocks XSS, SQLi, and common application attack vectors
2. `AWSManagedRulesKnownBadInputsRuleSet` — blocks known malicious inputs (Log4Shell, etc.)
3. `AWSManagedRulesAmazonIpReputationList` — blocks IPs from botnets and known attack infrastructure

### Requirement: Rate Limiting on Authentication Endpoints

The system SHALL enforce rate limiting rules on authentication endpoints to protect against brute-force and replay attacks:

- `/login`: maximum 100 requests per 5 minutes per source IP
- `/callback`: maximum 100 requests per 5 minutes per source IP

#### Scenario: Rate limit exceeded on /login

WHEN a single IP sends more than 100 requests to `/login` within a 5-minute window
THEN the WAF SHALL block subsequent requests from that IP for the remainder of the window

### Requirement: Shield Standard Coverage

The system SHALL benefit from AWS Shield Standard protection on all ALB and CloudFront resources, providing layer 3 and 4 DDoS mitigation at no additional cost.

### Requirement: Open Security Issues Tracked

The following issues are documented and open. The system SHALL NOT be considered production-ready until all Medium and above issues are remediated:

| ID | Severity | Description |
|---|---|---|
| SEC-002 | Medium | IAM policy downloaded without SHA256 hash verification |
| SEC-003 | Low | Sample app image uses implicit `latest` tag without digest pinning |
| SEC-004 | Medium | `AmazonEKSClusterAdminPolicy` scoped to entire cluster |
| SEC-005 | Low | ALB Security Groups allow `0.0.0.0/0` by default |
| SEC-006 | Medium | IMDSv1 enabled on nodes — credentials accessible via SSRF |

### Requirement: ALB Inbound Restriction (Planned)

The system SHALL restrict ALB Security Group inbound rules to the Global Accelerator IP ranges (`35.191.0.0/16`, `130.211.0.0/22`) to prevent direct ALB access bypassing the WAF. This addresses SEC-005.
