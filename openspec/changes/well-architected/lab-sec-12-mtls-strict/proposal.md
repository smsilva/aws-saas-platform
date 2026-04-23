# Proposal: LAB-SEC-12 — Istio mTLS Strict Mode

## Problem

Istio is installed but operating in `PERMISSIVE` mode, which allows unencrypted plaintext traffic between pods. This means a compromised pod can send unencrypted requests to any service in the mesh.

## Scope

Add `PeerAuthentication` with `mode: STRICT` to all tenant and platform namespaces (`platform`, `auth`, `discovery`, `customer1`, `customer2`). This enforces zero-trust within the mesh — all pod-to-pod communication must use mTLS.
