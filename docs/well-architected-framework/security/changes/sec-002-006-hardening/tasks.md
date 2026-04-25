# Tasks: Security Hardening

## SEC-002 — IAM Policy Hash Verification

- [ ] Look up the SHA256 hash for the ALB Controller IAM policy at the pinned version in `env.conf`
- [ ] Add `sha256sum --check` after the `curl` download in `scripts/04-install-alb-controller`
- [ ] Test: run the script in a clean environment and verify it exits non-zero if the hash is tampered
- [ ] Update `docs/security-issues/sec-002.md` status to Resolved

## SEC-003 — Image Digest Pinning

- [ ] Retrieve the SHA256 digest for `mccutchen/go-httpbin` (or pinned `kennethreitz/httpbin`) using `docker manifest inspect` or `crane digest`
- [ ] Replace the image reference in `scripts/08-deploy-sample-app` with the digest-pinned form
- [ ] Test: run the script and confirm the pod starts with the correct image
- [ ] Update `docs/security-issues/sec-003.md` status to Resolved

## SEC-004 — Least-Privilege EKS Access (Documentation)

- [ ] Add a comment block in `scripts/03-configure-access` stating the production recommendation
- [ ] Update `docs/security-issues/sec-004.md` status to Documented (Lab-Only Intentional)

## SEC-005 — ALB Inbound CIDR Restriction

- [ ] Add `alb.ingress.kubernetes.io/inbound-cidrs: "35.191.0.0/16,130.211.0.0/22"` to the Ingress YAML in `scripts/07-configure-alb-ingress`
- [ ] Test: verify ALB Security Group is updated after `kubectl apply`
- [ ] Test: direct HTTP request to ALB DNS (bypassing Global Accelerator) is rejected
- [ ] Update `docs/security-issues/sec-005.md` status to Resolved

## SEC-006 — IMDSv2 Enforcement

- [ ] Add `instanceMetadataOptions: httpTokens: required, httpPutResponseHopLimit: 1` to the eksctl config in `scripts/02-create-cluster`
- [ ] Document in the script that this requires cluster recreation if nodes already exist
- [ ] Test: from within a pod, confirm `curl http://169.254.169.254/latest/meta-data/` returns 401
- [ ] Update `docs/security-issues/sec-006.md` status to Resolved

## Final

- [ ] Update `docs/security/index.md` — mark all five issues resolved
- [ ] Run `make test` — all tests pass
- [ ] Commit with `fix(scripts): remediate SEC-002, SEC-003, SEC-005, SEC-006`
