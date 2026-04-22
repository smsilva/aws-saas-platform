# Metadata Diff — Bash (eksctl) vs Terraform

Clusters comparados:
- **Bash**: `wasp-cool-whale-7zr5` (eksctl 0.225.0)
- **Terraform**: `wasp` (módulo terraform-aws-modules/eks)

Data da captura: 2026-04-22

---

## Resumo

- O cluster Terraform tem **criptografia de secrets com KMS** (`encryptionConfig`); o Bash não configura isso.
- O cluster Terraform tem **endpoint privado habilitado** (`endpointPrivateAccess: true`); o Bash deixa apenas público.
- O cluster Terraform habilita **logs de API, audit e authenticator**; o Bash não habilita nenhum log.
- O cluster Terraform usa uma **policy de criptografia customizada** no cluster role (`wasp-cluster-ClusterEncryption*`), enquanto o Bash usa `AmazonEKSVPCResourceController` (que o Terraform omite).
- O nodegroup Bash tem `minSize: 2`; o Terraform tem `minSize: 1`.
- O nodegroup Bash usa `maxUnavailable: 1` para updates; o Terraform usa `maxUnavailablePercentage: 33`.
- O Bash instala **4 addons** (coredns, kube-proxy, metrics-server, vpc-cni); o Terraform instala **3** (sem metrics-server).
- As versões dos addons diferem: coredns `v1.12.4` (Bash) vs `v1.13.2` (TF); vpc-cni `v1.20.4` (Bash) vs `v1.21.1` (TF); kube-proxy `v1.34.6-eksbuild.2` (Bash) vs `v1.34.6-eksbuild.5` (TF).
- O addon vpc-cni do Bash tem **IRSA configurado**; o do Terraform não tem `serviceAccountRoleArn`.
- O Bash tem **4 access entries** (inclui SSO admin role); o Terraform tem **3** (sem a SSO role).
- O launch template do Terraform tem **2 security groups** no nó (cluster SG + node SG dedicado); o Bash usa apenas o cluster SG primário.
- O Terraform cria um **node security group dedicado** (`wasp-node`) com regras explícitas de ingress (10250, 443, 6443, 9443, 8443, 4443, 53/tcp, 53/udp, 1025-65535); o Bash usa o cluster SG primário com acesso mais amplo.
- O OIDC provider do Bash não tem tags `project`/`env`; o do Terraform está corretamente taggeado.
- Os addons do Terraform têm tags `project`/`env`; os do Bash não têm nenhuma tag.

---

## Tabela por categoria

### Cluster Config

| Campo | Bash | Terraform | Impacto |
|---|---|---|---|
| `name` | `wasp-cool-whale-7zr5` | `wasp` | Cosmético |
| `endpointPrivateAccess` | `false` | `true` | Segurança: nodes em subnet privada podem alcançar a API internamente sem sair para internet |
| `endpointPublicAccess` | `true` | `true` | Igual |
| `publicAccessCidrs` | `0.0.0.0/0` | `0.0.0.0/0` | Igual — ambos expõem o endpoint públicamente sem restrição de CIDR |
| `logging.api` | desabilitado | habilitado | Observabilidade/auditoria |
| `logging.audit` | desabilitado | habilitado | Segurança — obrigatório para compliance |
| `logging.authenticator` | desabilitado | habilitado | Troubleshooting de autenticação |
| `logging.controllerManager` | desabilitado | desabilitado | Igual |
| `logging.scheduler` | desabilitado | desabilitado | Igual |
| `encryptionConfig` | ausente | secrets com KMS `03704aa8-87e1-4428-975f-049f44231cfe` | Segurança — secrets em etcd criptografados em repouso |
| `authenticationMode` | `API_AND_CONFIG_MAP` | `API_AND_CONFIG_MAP` | Igual |
| `upgradePolicy.supportType` | `EXTENDED` | `EXTENDED` | Igual |
| `serviceIpv4Cidr` | `172.20.0.0/16` | `172.20.0.0/16` | Igual |
| Subnets no cluster | 4 (2 públicas + 2 privadas) | 2 (privadas) | Terraform usa apenas subnets privadas para o control plane |
| Tags do cluster | eksctl + `project`/`env` | apenas `project`/`env` | Terraform não inclui tags de tooling |

### Nodegroup

| Campo | Bash | Terraform | Impacto |
|---|---|---|---|
| `instanceTypes` | `t3.medium` | `t3.medium` | Igual |
| `amiType` | `AL2023_x86_64_STANDARD` | `AL2023_x86_64_STANDARD` | Igual |
| `capacityType` | `ON_DEMAND` | `ON_DEMAND` | Igual |
| `scalingConfig.minSize` | `2` | `1` | Custo: Terraform permite cluster com 1 node |
| `scalingConfig.maxSize` | `5` | `5` | Igual |
| `scalingConfig.desiredSize` | `2` | `2` | Igual |
| `updateConfig` | `maxUnavailable: 1` | `maxUnavailablePercentage: 33` | Com 2 nodes, 33% = 0 (arredondado para baixo) — Bash é mais conservador e explícito |
| `labels` | `alpha.eksctl.io/cluster-name`, `alpha.eksctl.io/nodegroup-name` | `{}` (vazio) | Terraform não adiciona labels no nodegroup |
| Subnets do nodegroup | `subnet-083e7a630a8a8ad5e`, `subnet-0e4bd4d2526f45a75` (privadas) | `subnet-04268ed7064f41ff9`, `subnet-09c148c07fde8d64e` (privadas) | Ambos em subnets privadas |

### Launch Template

| Campo | Bash | Terraform | Impacto |
|---|---|---|---|
| `BlockDeviceMappings` | `/dev/xvda`, 80GB, gp3, IOPS 3000, Throughput 125 | ausente (sem disco explícito) | Terraform usa o default da AMI (geralmente 20GB gp2) — disco menor e mais lento |
| `SecurityGroupIds` | `[sg-001028cc8b7173d05]` (cluster primary SG) | `[sg-0c348328e6d5c13a1, sg-0e9304f4191605032]` (cluster SG + node SG) | Terraform usa SG dedicado para nós com regras explícitas |
| `MetadataOptions.HttpTokens` | `required` (IMDSv2) | `required` (IMDSv2) | Igual — ambos forçam IMDSv2 |
| `MetadataOptions.HttpPutResponseHopLimit` | `2` | `2` | Igual — necessário para containers |
| `MetadataOptions.HttpEndpoint` | não declarado (default `enabled`) | `enabled` (explícito) | Igual em resultado; Terraform é explícito |
| `UserData` | não declarado | `""` (vazio explícito) | Funcional igual; Terraform declara explicitamente |
| Tags nas instâncias | `Name`, eksctl tags, `env`, `project` | `Name`, `env`, `project` | Terraform não inclui tags de tooling eksctl |

### Addons

| Addon | Versão Bash | Versão Terraform | Status Bash | Status Terraform | Diferença |
|---|---|---|---|---|---|
| coredns | `v1.12.4-eksbuild.10` | `v1.13.2-eksbuild.7` | DEGRADED (sem nodes no momento) | ACTIVE | Terraform usa versão mais nova |
| kube-proxy | `v1.34.6-eksbuild.2` | `v1.34.6-eksbuild.5` | ACTIVE | ACTIVE | Terraform usa build mais recente |
| vpc-cni | `v1.20.4-eksbuild.2` | `v1.21.1-eksbuild.7` | ACTIVE | ACTIVE | Terraform usa versão mais nova |
| metrics-server | `v0.8.1-eksbuild.6` | ausente | ACTIVE | — | Terraform não instala metrics-server |
| Tags nos addons | `{}` (sem tags) | `{env: lab, project: eks-lab}` | — | — | Terraform taga os addons |
| IRSA no vpc-cni | `serviceAccountRoleArn` configurado | ausente | — | — | Bash configura IRSA para vpc-cni via eksctl |

### Access Entries

| Principal | Bash | Terraform | Tipo |
|---|---|---|---|
| `AWSServiceRoleForAmazonEKS` | presente | presente | `STANDARD`, `eks:managed` |
| node instance role | `eksctl-*-NodeInstanceRole-weWwUGt9zWc4` | `default-eks-node-group-*` | `EC2_LINUX`, `system:nodes` |
| `user/silvios` | presente | presente | `STANDARD` |
| `AWSReservedSSO_AdministratorAccess_f7ded39be32ff185` | **presente** | **ausente** | `STANDARD` |
| Tags no access entry silvios | `{}` (sem tags) | `{env: lab, project: eks-lab}` | — |

### IAM — Cluster Role

| Aspecto | Bash | Terraform |
|---|---|---|
| Role name | `eksctl-wasp-cool-whale-7zr5-cluster-ServiceRole-nZvK1rKt36Iq` | `wasp-cluster-20260422232336609300000001` |
| `AmazonEKSClusterPolicy` | presente | presente |
| `AmazonEKSVPCResourceController` | **presente** | **ausente** |
| `wasp-cluster-ClusterEncryption*` (inline) | **ausente** | **presente** (necessária pelo KMS) |
| Tags | eksctl tags + `project`/`env` | apenas `project`/`env` |
| `sts:TagSession` | Action listada | Action listada |

### IAM — Node Role

| Aspecto | Bash | Terraform |
|---|---|---|
| Role name | `eksctl-wasp-cool-whale-7zr5-nodegr-NodeInstanceRole-weWwUGt9zWc4` | `default-eks-node-group-20260422232353803100000007` |
| `AmazonEKSWorkerNodePolicy` | presente | presente |
| `AmazonEC2ContainerRegistryReadOnly` | presente | presente |
| `AmazonEKS_CNI_Policy` | presente | presente |
| Description | `""` | `"EKS managed node group IAM role"` |
| Tags | eksctl tags + `project`/`env` | apenas `project`/`env` |

### Security Groups

| SG | Bash | Terraform | Diferença |
|---|---|---|---|
| Cluster primary SG | `sg-001028cc8b7173d05` — ingress: self + unmanaged nodes (all traffic) | `sg-0c348328e6d5c13a1` — ingress: apenas nodes SG na 443/tcp | Terraform tem ingress mais restrito no cluster SG |
| Additional cluster SG | `sg-0562ab53a4eecec58` — ControlPlaneSecurityGroup (eksctl), sem ingress rules | `sg-0b4bb928c6eabb137` — ingress da 443/tcp a partir do node SG | Terraform usa SG dedicado com regra 443 explícita |
| Node dedicated SG | ausente | `sg-0e9304f4191605032` — regras explícitas: 443, 6443, 8443, 9443, 4443, 10250, 10251, 53/tcp, 53/udp, 1025-65535 | Terraform cria SG dedicado para nós com regras granulares |
| Egress nos nodes | `0.0.0.0/0` (amplo) | `0.0.0.0/0` (amplo) | Igual |

---

## Gaps

### O que o Terraform faz que o Bash não faz

- **KMS encryption de secrets**: `encryptionConfig` com chave KMS gerenciada pelo Terraform.
- **Endpoint privado**: `endpointPrivateAccess: true` — nodes resolvem o API server internamente.
- **Logs de controle plane**: api, audit e authenticator habilitados.
- **Node SG dedicado com regras explícitas**: `sg-0e9304f4191605032` com regras granulares de ingress/egress; o Bash usa o cluster primary SG que é mais permissivo.
- **OIDC e access entries taggeados**: tags `project`/`env` em todos os recursos IAM e addons.
- **Cluster SG com ingress 443 explícito**: ao invés do "allow all" do Bash.

### O que o Bash faz que o Terraform não faz

- **metrics-server addon**: instalado como addon gerenciado EKS (`v0.8.1-eksbuild.6`); o Terraform não instala.
- **IRSA para vpc-cni**: `serviceAccountRoleArn` configurado no addon; o Terraform usa a policy `AmazonEKS_CNI_Policy` diretamente no node role (sem IRSA).
- **`AmazonEKSVPCResourceController` no cluster role**: policy necessária para recursos de rede avançados (Security Groups for Pods). O Terraform omite essa policy.
- **SSO admin role no access entry**: `AWSReservedSSO_AdministratorAccess_f7ded39be32ff185` adicionado como access entry; útil para acesso via AWS SSO/Identity Center.
- **EBS explícito no launch template**: 80GB gp3 com IOPS 3000 e throughput 125MB/s configurados explicitamente; o Terraform usa o default da AMI (20GB gp2).
- **nodegroup minSize: 2**: garante alta disponibilidade mínima; o Terraform permite 1 node.
- **Labels no nodegroup**: `alpha.eksctl.io/cluster-name` e `alpha.eksctl.io/nodegroup-name` para identificação de origem.

---

## Recomendações

### 1. Adicionar metrics-server addon

**Arquivo**: `lab/aws/eks/terraform/modules/eks/main.tf` (ou onde os addons são declarados)

```hcl
resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "metrics-server"
  addon_version = "v0.8.1-eksbuild.6"

  tags = var.tags
}
```

Necessário para `kubectl top nodes/pods` e para HPA funcionar sem Prometheus.

### 2. Configurar EBS explícito no launch template

**Arquivo**: `lab/aws/eks/terraform/modules/eks/main.tf` — bloco `aws_launch_template`

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

O default da AMI AL2023 é 20GB gp2. Com cargas de trabalho que geram logs ou têm imagens grandes, 20GB esgota rapidamente.

### 3. Adicionar `AmazonEKSVPCResourceController` ao cluster role

**Arquivo**: `lab/aws/eks/terraform/modules/eks/main.tf` — bloco `aws_iam_role_policy_attachment` do cluster role

```hcl
resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
```

Necessário se o lab vier a usar Security Groups for Pods (`ENIConfig`). Sem essa policy, o recurso falha silenciosamente.

### 4. Configurar IRSA para vpc-cni

**Arquivo**: `lab/aws/eks/terraform/modules/eks/main.tf`

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

Usar IRSA em vez da policy no node role segue o princípio do menor privilégio: outros pods no node não herdam permissões de rede do vpc-cni.

### 5. Adicionar SSO admin role ao access entry

**Arquivo**: `lab/aws/eks/terraform/modules/eks/main.tf` ou `variables.tf`

```hcl
variable "sso_admin_role_arn" {
  description = "ARN da role SSO AdministratorAccess para acesso ao cluster"
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

Sem esse entry, operadores com acesso via SSO/Identity Center não conseguem usar `kubectl` mesmo tendo permissão AWS.

### 6. Ajustar nodegroup minSize para 2

**Arquivo**: `lab/aws/eks/terraform/modules/eks/main.tf` — bloco `aws_eks_node_group` ou variável correspondente

```hcl
scaling_config {
  min_size     = 2   # era 1
  max_size     = 5
  desired_size = 2
}
```

Com `minSize: 1`, um evento de substituição de node pode colocar o cluster em estado degradado temporariamente.

### 7. Ajustar updateConfig do nodegroup

**Arquivo**: `lab/aws/eks/terraform/modules/eks/main.tf`

```hcl
update_config {
  max_unavailable = 1   # trocar maxUnavailablePercentage: 33 por valor absoluto
}
```

Com 2 nodes, `maxUnavailablePercentage: 33` resulta em 0 (arredonda para baixo), impedindo updates de prosseguir. Usar valor absoluto `1` garante que o update funcione independente do tamanho do nodegroup.
