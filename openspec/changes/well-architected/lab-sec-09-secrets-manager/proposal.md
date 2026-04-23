# Proposal: LAB-SEC-09 — AWS Secrets Manager

## Problem

`COGNITO_CLIENT_SECRET_*` and `STATE_JWT_SECRET` are currently stored as plaintext values passed via `kubectl apply` or hardcoded in scripts. These secrets have no rotation policy and no audit trail.

## Scope

Create one secret per tenant and one for the JWT signing key in AWS Secrets Manager under the `wasp/lab/` prefix. This is the prerequisite for LAB-SEC-10 (ESO) and LAB-SEC-11 (ExternalSecret).

## Relation to Other Changes

- **Prerequisite**: LAB-SEC-08 (etcd encryption) must be complete first
- **Required by**: LAB-SEC-10, LAB-SEC-11
