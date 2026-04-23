# Proposal: LAB-SEC-10 — External Secrets Operator

## Problem

There is no mechanism to automatically sync secrets from AWS Secrets Manager into Kubernetes. Secrets are applied manually via scripts, creating operational risk and no rotation path.

## Scope

Install External Secrets Operator (ESO) via Helm and create a `SecretStore` in namespace `auth` that authenticates to Secrets Manager via IRSA. This is the operator foundation required by LAB-SEC-11.

## Relation to Other Changes

- **Prerequisite**: LAB-SEC-09 (secrets must exist in Secrets Manager)
- **Required by**: LAB-SEC-11
