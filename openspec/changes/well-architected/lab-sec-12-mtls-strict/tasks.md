# Tasks: LAB-SEC-12 — Istio mTLS Strict Mode

## Checklist

- [ ] Add `PeerAuthentication mode: STRICT` to namespaces: `platform`, `auth`, `discovery`, `customer1`, `customer2`
- [ ] Verify no non-sidecar pods exist in those namespaces
- [ ] Test: internal service-to-service calls still succeed
