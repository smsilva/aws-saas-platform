# Proposal: LAB-SEC-11 — ExternalSecret for callback-handler

## Problem

`callback-handler-secret` is applied manually via `scripts/13-deploy-services`. Adding a new tenant requires editing a script, reapplying, and restarting the pod. There is no automated sync or rotation.

## Scope

Replace the manually managed `callback-handler-secret` Kubernetes Secret with an `ExternalSecret` resource that syncs from AWS Secrets Manager via ESO. Remove the manual `kubectl apply` call from the deployment script.

## Relation to Other Changes

- **Prerequisite**: LAB-SEC-10 (ESO + SecretStore must be installed)
