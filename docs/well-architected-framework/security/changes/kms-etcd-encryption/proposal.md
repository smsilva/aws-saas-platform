# Proposal: LAB-SEC-08 — KMS Encryption for etcd

## Problem

EKS etcd stores Kubernetes Secrets in plaintext by default. Without envelope encryption via a KMS Customer Managed Key, any AWS-level access to the etcd volume exposes all secrets, including Cognito client secrets and JWT signing keys.

## Scope

Create a KMS CMK in `us-east-1` and enable secrets encryption on the EKS cluster. This is a P0 prerequisite for LAB-SEC-09~11 (Secrets Manager + ESO), because ExternalSecret resources are themselves stored in etcd.

## Relation to Other Changes

- **Prerequisite for**: LAB-SEC-09, LAB-SEC-10, LAB-SEC-11
- **security-hardening**: covers SEC-002~006 — do not duplicate here
