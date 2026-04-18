# Design: Security Hardening

## SEC-002 — IAM Policy Hash Verification

**File:** `scripts/04-install-alb-controller`

After the `curl` download, add a `sha256sum -c` check. The expected hash must be pinned per ALB Controller version and stored in the script or in `scripts/env.conf`. If the hash does not match, the script must exit non-zero before calling `aws iam create-policy`.

```bash
expected_hash="<sha256 of the pinned version>"
echo "${expected_hash}  /tmp/alb-iam-policy.json" | sha256sum --check --quiet \
  || { echo "ERROR: IAM policy hash mismatch — aborting"; exit 1; }
```

The hash must be obtained from the ALB Controller release notes for the pinned version.

## SEC-003 — Image Digest Pinning

**File:** `scripts/08-deploy-sample-app`

Replace the floating image reference with a digest-pinned one. Preferred alternative: `mccutchen/go-httpbin` (actively maintained, smaller image).

```bash
# Instead of: kennethreitz/httpbin
image: ghcr.io/mccutchen/go-httpbin@sha256:<digest>
```

The digest must be retrieved at the time of the fix with `docker manifest inspect` or `crane digest` and pinned in the script.

## SEC-004 — Least-Privilege EKS Access

**File:** `scripts/03-configure-access`

For lab use, document that `AmazonEKSClusterAdminPolicy` with `type=cluster` is intentional for the bootstrap phase only. Add a comment block in the script stating the production recommendation: use `AmazonEKSAdminPolicy` with `type=namespace` scoped to the namespaces the operator manages.

No automated enforcement in the lab — the script stays as-is with the documentation added.

## SEC-005 — ALB Inbound CIDR Restriction

**File:** `scripts/07-configure-alb-ingress` (the Ingress YAML)

Add the annotation:

```yaml
alb.ingress.kubernetes.io/inbound-cidrs: "35.191.0.0/16,130.211.0.0/22"
```

This restricts ALB Security Group inbound rules to the Global Accelerator edge IP ranges, preventing direct ALB access that bypasses the WAF.

## SEC-006 — IMDSv2 Enforcement

**File:** `scripts/02-create-cluster` (eksctl config YAML)

Add to the managed node group definition:

```yaml
instanceMetadataOptions:
  httpTokens: required
  httpPutResponseHopLimit: 1
```

`httpPutResponseHopLimit: 1` ensures the IMDSv2 token does not traverse the container network overlay, blocking IMDS access from within pods even with a valid token.

> Note: This change requires recreating the node group or the cluster, as `instanceMetadataOptions` cannot be changed in place on existing nodes.
