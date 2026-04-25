# Metadata Diff — Bash (eksctl) vs Terraform

Clusters compared:
- **Bash**: `wasp-cool-whale-7zr5` (eksctl 0.225.0)
- **Terraform**: `wasp` (module terraform-aws-modules/eks)

Captured on: 2026-04-22

---

## Summary

- The Terraform cluster has **KMS secrets encryption** (`encryptionConfig`); the Bash cluster does not configure this.
- The Terraform cluster has the **private endpoint enabled** (`endpointPrivateAccess: true`); the Bash cluster leaves only the public endpoint.
- The Terraform cluster enables **API, audit, and authenticator logs**; the Bash cluster enables no logs.
- The Terraform cluster uses a **custom encryption policy** on the cluster role (`wasp-cluster-ClusterEncryption*`), while Bash uses `AmazonEKSVPCResourceController` (which Terraform omits).
- The Bash nodegroup has `minSize: 2`; Terraform has `minSize: 1`.
- The Bash nodegroup uses `maxUnavailable: 1` for updates; Terraform uses `maxUnavailablePercentage: 33`.
- Bash installs **4 addons** (coredns, kube-proxy, metrics-server, vpc-cni); Terraform installs **3** (no metrics-server).
- Addon versions differ: coredns `v1.12.4` (Bash) vs `v1.13.2` (TF); vpc-cni `v1.20.4` (Bash) vs `v1.21.1` (TF); kube-proxy `v1.34.6-eksbuild.2` (Bash) vs `v1.34.6-eksbuild.5` (TF).
- The Bash vpc-cni addon has **IRSA configured**; the Terraform one has no `serviceAccountRoleArn`.
- Bash has **4 access entries** (includes SSO admin role); Terraform has **3** (no SSO role).
- The Terraform launch template has **2 security groups** on the node (cluster SG + dedicated node SG); Bash uses only the primary cluster SG.
- Terraform creates a **dedicated node security group** (`wasp-node`) with explicit ingress rules (10250, 443, 6443, 9443, 8443, 4443, 53/tcp, 53/udp, 1025-65535); Bash uses the primary cluster SG with broader access.
- The Bash OIDC provider has no `project`/`env` tags; the Terraform one is correctly tagged.
- Terraform addons have `project`/`env` tags; Bash addons have no tags.

---

## Table by category

### Cluster Config

| Field | Bash | Terraform | Impact |
|---|---|---|---|
| `name` | `wasp-cool-whale-7zr5` | `wasp` | Cosmetic |
| `endpointPrivateAccess` | `false` | `true` | Security: nodes in private subnets can reach the API internally without leaving for the internet |
| `endpointPublicAccess` | `true` | `true` | Same |
| `publicAccessCidrs` | `0.0.0.0/0` | `0.0.0.0/0` | Same — both expose the endpoint publicly without CIDR restriction |
| `logging.api` | disabled | enabled | Observability/auditing |
| `logging.audit` | disabled | enabled | Security — required for compliance |
| `logging.authenticator` | disabled | enabled | Authentication troubleshooting |
| `logging.controllerManager` | disabled | disabled | Same |
| `logging.scheduler` | disabled | disabled | Same |
| `encryptionConfig` | absent | secrets with KMS `03704aa8-87e1-4428-975f-049f44231cfe` | Security — secrets in etcd encrypted at rest |
| `authenticationMode` | `API_AND_CONFIG_MAP` | `API_AND_CONFIG_MAP` | Same |
| `upgradePolicy.supportType` | `EXTENDED` | `EXTENDED` | Same |
| `serviceIpv4Cidr` | `172.20.0.0/16` | `172.20.0.0/16` | Same |
| Cluster subnets | 4 (2 public + 2 private) | 2 (private) | Terraform uses only private subnets for the control plane |
| Cluster tags | eksctl + `project`/`env` | `project`/`env` only | Terraform does not include tooling tags |

### Nodegroup

| Field | Bash | Terraform | Impact |
|---|---|---|---|
| `instanceTypes` | `t3.medium` | `t3.medium` | Same |
| `amiType` | `AL2023_x86_64_STANDARD` | `AL2023_x86_64_STANDARD` | Same |
| `capacityType` | `ON_DEMAND` | `ON_DEMAND` | Same |
| `scalingConfig.minSize` | `2` | `1` | Cost: Terraform allows cluster with 1 node |
| `scalingConfig.maxSize` | `5` | `5` | Same |
| `scalingConfig.desiredSize` | `2` | `2` | Same |
| `updateConfig` | `maxUnavailable: 1` | `maxUnavailablePercentage: 33` | With 2 nodes, 33% = 0 (rounded down) — Bash is more conservative and explicit |
| `labels` | `alpha.eksctl.io/cluster-name`, `alpha.eksctl.io/nodegroup-name` | `{}` (empty) | Terraform adds no labels to the nodegroup |
| Nodegroup subnets | `subnet-083e7a630a8a8ad5e`, `subnet-0e4bd4d2526f45a75` (private) | `subnet-04268ed7064f41ff9`, `subnet-09c148c07fde8d64e` (private) | Both in private subnets |

### Launch Template

| Field | Bash | Terraform | Impact |
|---|---|---|---|
| `BlockDeviceMappings` | `/dev/xvda`, 80GB, gp3, IOPS 3000, Throughput 125 | absent (no explicit disk) | Terraform uses the AMI default (typically 20GB gp2) — smaller and slower disk |
| `SecurityGroupIds` | `[sg-001028cc8b7173d05]` (cluster primary SG) | `[sg-0c348328e6d5c13a1, sg-0e9304f4191605032]` (cluster SG + node SG) | Terraform uses a dedicated node SG with explicit rules |
| `MetadataOptions.HttpTokens` | `required` (IMDSv2) | `required` (IMDSv2) | Same — both enforce IMDSv2 |
| `MetadataOptions.HttpPutResponseHopLimit` | `2` | `2` | Same — required for containers |
| `MetadataOptions.HttpEndpoint` | not declared (default `enabled`) | `enabled` (explicit) | Same result; Terraform is explicit |
| `UserData` | not declared | `""` (explicitly empty) | Functionally equivalent; Terraform declares it explicitly |
| Instance tags | `Name`, eksctl tags, `env`, `project` | `Name`, `env`, `project` | Terraform does not include eksctl tooling tags |

### Addons

| Addon | Bash version | Terraform version | Bash status | Terraform status | Difference |
|---|---|---|---|---|---|
| coredns | `v1.12.4-eksbuild.10` | `v1.13.2-eksbuild.7` | DEGRADED (no nodes at the time) | ACTIVE | Terraform uses newer version |
| kube-proxy | `v1.34.6-eksbuild.2` | `v1.34.6-eksbuild.5` | ACTIVE | ACTIVE | Terraform uses more recent build |
| vpc-cni | `v1.20.4-eksbuild.2` | `v1.21.1-eksbuild.7` | ACTIVE | ACTIVE | Terraform uses newer version |
| metrics-server | `v0.8.1-eksbuild.6` | absent | ACTIVE | — | Terraform does not install metrics-server |
| Addon tags | `{}` (no tags) | `{env: lab, project: eks-lab}` | — | — | Terraform tags addons |
| IRSA on vpc-cni | `serviceAccountRoleArn` configured | absent | — | — | Bash configures IRSA for vpc-cni via eksctl |

### Access Entries

| Principal | Bash | Terraform | Type |
|---|---|---|---|
| `AWSServiceRoleForAmazonEKS` | present | present | `STANDARD`, `eks:managed` |
| node instance role | `eksctl-*-NodeInstanceRole-weWwUGt9zWc4` | `default-eks-node-group-*` | `EC2_LINUX`, `system:nodes` |
| `user/silvios` | present | present | `STANDARD` |
| `AWSReservedSSO_AdministratorAccess_f7ded39be32ff185` | **present** | **absent** | `STANDARD` |
| Tags on silvios access entry | `{}` (no tags) | `{env: lab, project: eks-lab}` | — |

### IAM — Cluster Role

| Aspect | Bash | Terraform |
|---|---|---|
| Role name | `eksctl-wasp-cool-whale-7zr5-cluster-ServiceRole-nZvK1rKt36Iq` | `wasp-cluster-20260422232336609300000001` |
| `AmazonEKSClusterPolicy` | present | present |
| `AmazonEKSVPCResourceController` | **present** | **absent** |
| `wasp-cluster-ClusterEncryption*` (inline) | **absent** | **present** (required by KMS) |
| Tags | eksctl tags + `project`/`env` | `project`/`env` only |
| `sts:TagSession` | Action listed | Action listed |

### IAM — Node Role

| Aspect | Bash | Terraform |
|---|---|---|
| Role name | `eksctl-wasp-cool-whale-7zr5-nodegr-NodeInstanceRole-weWwUGt9zWc4` | `default-eks-node-group-20260422232353803100000007` |
| `AmazonEKSWorkerNodePolicy` | present | present |
| `AmazonEC2ContainerRegistryReadOnly` | present | present |
| `AmazonEKS_CNI_Policy` | present | present |
| Description | `""` | `"EKS managed node group IAM role"` |
| Tags | eksctl tags + `project`/`env` | `project`/`env` only |

### Security Groups

| SG | Bash | Terraform | Difference |
|---|---|---|---|
| Cluster primary SG | `sg-001028cc8b7173d05` — ingress: self + unmanaged nodes (all traffic) | `sg-0c348328e6d5c13a1` — ingress: node SG on 443/tcp only | Terraform has more restricted ingress on the cluster SG |
| Additional cluster SG | `sg-0562ab53a4eecec58` — ControlPlaneSecurityGroup (eksctl), no ingress rules | `sg-0b4bb928c6eabb137` — ingress of 443/tcp from node SG | Terraform uses a dedicated SG with an explicit 443 rule |
| Node dedicated SG | absent | `sg-0e9304f4191605032` — explicit rules: 443, 6443, 8443, 9443, 4443, 10250, 10251, 53/tcp, 53/udp, 1025-65535 | Terraform creates a dedicated node SG with granular rules |
| Node egress | `0.0.0.0/0` (broad) | `0.0.0.0/0` (broad) | Same |

---

## Gaps

### What Terraform does that Bash does not

- **KMS secrets encryption**: `encryptionConfig` with a KMS key managed by Terraform.
- **Private endpoint**: `endpointPrivateAccess: true` — nodes resolve the API server internally.
- **Control plane logs**: api, audit, and authenticator enabled.
- **Dedicated node SG with explicit rules**: `sg-0e9304f4191605032` with granular ingress/egress rules; Bash uses the cluster primary SG which is more permissive.
- **Tagged OIDC and access entries**: `project`/`env` tags on all IAM resources and addons.
- **Cluster SG with explicit 443 ingress**: instead of Bash's "allow all".

### What Bash does that Terraform does not

- **metrics-server addon**: installed as a managed EKS addon (`v0.8.1-eksbuild.6`); Terraform does not install it.
- **IRSA for vpc-cni**: `serviceAccountRoleArn` configured on the addon; Terraform uses `AmazonEKS_CNI_Policy` directly on the node role (no IRSA).
- **`AmazonEKSVPCResourceController` on the cluster role**: policy required for advanced networking features (Security Groups for Pods). Terraform omits this policy.
- **SSO admin role in access entry**: `AWSReservedSSO_AdministratorAccess_f7ded39be32ff185` added as an access entry; useful for access via AWS SSO/Identity Center.
- **Explicit EBS in launch template**: 80GB gp3 with IOPS 3000 and throughput 125MB/s configured explicitly; Terraform uses the AMI default (20GB gp2).
- **nodegroup minSize: 2**: ensures minimum high availability; Terraform allows 1 node.
- **Nodegroup labels**: `alpha.eksctl.io/cluster-name` and `alpha.eksctl.io/nodegroup-name` for origin identification.

---

## Recommendations

### 1. Add metrics-server addon

**File**: `lab/aws/eks/terraform/modules/eks/main.tf` (or wherever addons are declared)

```hcl
resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "metrics-server"
  addon_version = "v0.8.1-eksbuild.6"

  tags = var.tags
}
```

Required for `kubectl top nodes/pods` and for HPA to work without Prometheus.

### 2. Configure explicit EBS in the launch template

**File**: `lab/aws/eks/terraform/modules/eks/main.tf` — `aws_launch_template` block

```hcl
block_device_mappings {
  device_name = "/dev/xvda"
  ebs {
    volume_size           = 80
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }
}
```

The AL2023 AMI default is 20GB gp2. With workloads that generate logs or have large images, 20GB fills up quickly.

### 3. Add `AmazonEKSVPCResourceController` to the cluster role

**File**: `lab/aws/eks/terraform/modules/eks/main.tf` — `aws_iam_role_policy_attachment` block for the cluster role

```hcl
resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
```

Required if the lab uses Security Groups for Pods (`ENIConfig`). Without this policy, the resource fails silently.

### 4. Configure IRSA for vpc-cni

**File**: `lab/aws/eks/terraform/modules/eks/main.tf`

```hcl
resource "aws_iam_role" "vpc_cni_irsa" {
  name = "${var.cluster_name}-vpc-cni-irsa"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_irsa_assume.json
  tags = var.tags
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni_irsa.arn
  tags = var.tags
}
```

Using IRSA instead of a policy on the node role follows the principle of least privilege: other pods on the node do not inherit vpc-cni networking permissions.

### 5. Add SSO admin role to access entry

**File**: `lab/aws/eks/terraform/modules/eks/main.tf` or `variables.tf`

```hcl
variable "sso_admin_role_arn" {
  description = "ARN of the SSO AdministratorAccess role for cluster access"
  type        = string
  default     = ""
}

resource "aws_eks_access_entry" "sso_admin" {
  count         = var.sso_admin_role_arn != "" ? 1 : 0
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.sso_admin_role_arn
  type          = "STANDARD"
  tags          = var.tags
}
```

Without this entry, operators with access via SSO/Identity Center cannot use `kubectl` even with AWS permissions.

### 6. Adjust nodegroup minSize to 2

**File**: `lab/aws/eks/terraform/modules/eks/main.tf` — `aws_eks_node_group` block or corresponding variable

```hcl
scaling_config {
  min_size     = 2   # was 1
  max_size     = 5
  desired_size = 2
}
```

With `minSize: 1`, a node replacement event can temporarily place the cluster in a degraded state.

### 7. Adjust nodegroup updateConfig

**File**: `lab/aws/eks/terraform/modules/eks/main.tf`

```hcl
update_config {
  max_unavailable = 1   # replace maxUnavailablePercentage: 33 with an absolute value
}
```

With 2 nodes, `maxUnavailablePercentage: 33` results in 0 (rounded down), preventing updates from proceeding. Using an absolute value of `1` ensures updates work regardless of nodegroup size.
