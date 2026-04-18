# Well-Architected Framework — Roadmap para Produção

## Contexto

Este documento registra sugestões de melhoria baseadas nos **6 pilares do AWS Well-Architected Framework**, considerando a transição do lab atual (Fase 1) para um ambiente de produção. As sugestões são ordenadas por prioridade e formuladas como itens incrementais de implementação.

A análise considera também a adoção de **VPN Client-to-Site com WireGuard** para tornar o control plane do EKS privado, mantendo os ALBs dos serviços acessíveis publicamente para tráfego de entrada.

---

## 🔐 Pilar 1 — Security

### 1.1 — EKS Control Plane Privado + VPN Client-to-Site (WireGuard)

**Gap atual:** o endpoint do control plane é público por padrão (`eksctl`). Qualquer pessoa com credenciais IAM válidas consegue alcançar a API do Kubernetes pela internet.

**Arquitetura proposta:**

```
Operador (laptop)
    │
    │  WireGuard tunnel (UDP 51820)
    ▼
EC2 "WireGuard gateway" (subnet pública, EIP)
    │
    │  VPC interno
    ▼
EKS API endpoint (privado, subnet privada)
    │
kubectl / helm / eksctl
```

O EC2 WireGuard age como bastion de rede (não SSH). Os operadores conectam o cliente WireGuard e, a partir daí, o endpoint privado do EKS fica acessível como se estivessem dentro da VPC. **Os ALBs e o Global Accelerator continuam públicos — nenhuma mudança no fluxo de tráfego de usuários finais.**

**Por que WireGuard:** kernel module nativo desde Linux 5.6, cliente open-source disponível para macOS/Windows/iOS/Android, sem dependência de OpenVPN.

**Itens de implementação:**

- `LAB-VPN-01`: Habilitar `endpointPrivateAccess: true` e `endpointPublicAccess: false` no cluster.
- `LAB-VPN-02`: Provisionar EC2 `t3.micro` em subnet pública com Security Group restrito (UDP 51820 dos IPs dos operadores).
- `LAB-VPN-03`: Instalar e configurar WireGuard no EC2 gateway; gerar par de chaves por operador.
- `LAB-VPN-04`: Adicionar rota no cliente WireGuard para o CIDR da VPC (`10.0.0.0/16`) via tunnel.
- `LAB-VPN-05`: Atualizar `kubeconfig` para apontar ao endpoint privado DNS (acessível apenas via VPN).
- `LAB-VPN-06`: Remover `endpointPublicAccess` e validar que `kubectl` só funciona com VPN ativa.

---

### 1.2 — Fechar issues de segurança documentadas (SEC-002 a SEC-006)

| Issue | Fix proposto |
|---|---|
| **SEC-002** — IAM policy sem hash | Fixar URL em versão específica e adicionar `sha256sum -c` no script `04-install-alb-controller` |
| **SEC-003** — Imagem sem digest | Substituir `kennethreitz/httpbin` por `docker.io/kennethreitz/httpbin@sha256:<digest>` ou `mccutchen/go-httpbin` |
| **SEC-004** — `cluster-admin` irrestrito | Criar IAM Role dedicado para operações; usar `cluster-admin` apenas para bootstrapping e revogar depois |
| **SEC-005** — SGs permissivos no ALB | Adicionar annotation `alb.ingress.kubernetes.io/inbound-cidrs` restringindo origem aos IPs do Global Accelerator (`35.191.0.0/16`, `130.211.0.0/22`) |
| **SEC-006** — IMDSv1 nos nodes | Confirmar/adicionar `httpTokens: required` no eksctl config para todos os node groups |

---

### 1.3 — Secrets Manager + External Secrets Operator

**Gap atual:** secrets de tenant armazenados como env vars em Kubernetes Secrets (base64 no etcd sem encryption at rest). Solução ótima já documentada nas Decisões Técnicas — estes itens a implementam.

- `LAB-SEC-08`: Habilitar **EKS Secrets Encryption** com KMS Customer Managed Key (`secretsEncryption.keyARN` no eksctl config). Pré-requisito para qualquer dado sensível no etcd.
- `LAB-SEC-09`: Criar secrets no AWS Secrets Manager para `COGNITO_CLIENT_SECRET_*` e `STATE_JWT_SECRET`.
- `LAB-SEC-10`: Instalar External Secrets Operator via Helm; criar `SecretStore` apontando para Secrets Manager via IRSA.
- `LAB-SEC-11`: Substituir o Kubernetes Secret manual do `callback-handler` por um `ExternalSecret` que sincroniza automaticamente.

---

### 1.4 — mTLS entre sidecars (Istio Strict Mode)

- `LAB-SEC-12`: Adicionar `PeerAuthentication` com `mode: STRICT` nos namespaces de tenant. Garante que qualquer comunicação pod-to-pod sem sidecar seja bloqueada — zero-trust dentro do cluster.

---

## 🏛️ Pilar 2 — Reliability

### 2.1 — Karpenter, PodDisruptionBudget e TopologySpread

- `LAB-REL-01`: Instalar **Karpenter** para provisionamento dinâmico de nodes — seleciona tipos de instância automaticamente, suporta Spot com fallback On-Demand, mais eficiente que Cluster Autoscaler.
- `LAB-REL-02`: Configurar `topologySpreadConstraints` nos deployments de `platform-frontend`, `callback-handler` e `discovery` para distribuir pods entre AZs.
- `LAB-REL-03`: Adicionar `PodDisruptionBudget` com `minAvailable: 1` para cada serviço crítico.

---

### 2.2 — Health Checks e Circuit Breaking

- `LAB-REL-04`: Confirmar/adicionar `livenessProbe` e `readinessProbe` nos deployments. O ALB Controller e o Istio usam esses probes para remover instâncias não saudáveis do pool.
- `LAB-REL-05`: Adicionar `DestinationRule` Istio com `outlierDetection` no `discovery` e no `callback-handler` — isola falhas de instâncias individuais sem derrubar o serviço inteiro.

---

### 2.3 — DynamoDB Global Tables (pré-requisito Fase 3)

- `LAB-REL-06`: Migrar `tenant-registry` para **DynamoDB Global Table** adicionando `eu-central-1` como réplica. Pré-requisito para que o discovery service funcione com latência local em múltiplas regiões.
- `LAB-REL-07`: Avaliar DAX apenas se p99 de latência do discovery superar 500ms em produção (conforme decisão técnica já documentada).

---

### 2.4 — Backup e Recovery

- `LAB-REL-08`: Habilitar **AWS Backup** para DynamoDB com retenção de 7 dias (point-in-time recovery).
- `LAB-REL-09`: Documentar e testar **RTO/RPO** para perda de um cluster regional — o GA faz failover de tráfego, mas o onboarding de novos tenants precisa ser region-aware.

---

## ⚡ Pilar 3 — Performance Efficiency

### 3.1 — Observabilidade de Performance

- `LAB-PERF-01`: Habilitar Istio telemetry com **Prometheus + Grafana** (`kube-prometheus-stack`) para métricas de latência, taxa de erro e throughput por VirtualService.
- `LAB-PERF-02`: Adicionar **Jaeger** ou **Tempo** para distributed tracing — o Istio já injeta headers `x-b3-*` nos sidecars; basta configurar o exporter.
- `LAB-PERF-03`: Criar dashboards por tenant para o `discovery` — latência p50/p99 de queries ao DynamoDB e taxa de cache hit (quando cache em memória for implementado).

---

### 3.2 — Right-sizing dos Nodes

- `LAB-PERF-04`: Após semanas de métricas reais, usar **Goldilocks** (VPA recommender) para ajustar `requests` e `limits` dos pods. `t3.medium` pode estar over/underprovisionado dependendo do perfil real de carga.

---

## 💰 Pilar 4 — Cost Optimization

### 4.1 — Spot Instances e Savings Plans

- `LAB-COST-01`: Configurar Karpenter (já citado em Reliability) com `NodePool` em mix de On-Demand para workloads de platform e Spot para workloads de tenant que toleram interrupção.
- `LAB-COST-02`: Avaliar **Savings Plans** para NAT Gateway e nodes de base que ficam sempre ativos.

---

### 4.2 — Custo do Global Accelerator

O GA custa ~$18/mês fixo por accelerator + $0.015/GB de tráfego processado.

- `LAB-COST-03`: No lab de desenvolvimento, considerar desligar o GA fora do horário de testes (os IPs anycast mudam, mas no lab isso é aceitável). Em produção, documentar o custo como item de linha fixo por perfil de failover (conforme modelo de dois tiers já definido nas Decisões Técnicas).

---

### 4.3 — Visibilidade de Custo por Tenant

- `LAB-COST-04`: Adicionar tags `tenant`, `environment` e `cluster` em todos os recursos AWS (EKS, ALB, WAF, DynamoDB, Cognito). Habilitar **Cost Allocation Tags** no Billing Console para relatório de custo por tenant.

---

## 🔧 Pilar 5 — Operational Excellence

### 5.1 — IaC e GitOps

**Gap atual:** provisionamento via scripts `01–17`. Funcional para lab, mas não idempotente nem auditável da mesma forma que IaC declarativa.

- `LAB-OPS-01`: Migrar scripts de infraestrutura AWS para **Terraform** (usando EKS Blueprints como referência, já citados nas Decisões Técnicas). Prioridade: VPC, EKS, IAM roles, DynamoDB, WAF WebACL.
- `LAB-OPS-02`: Adotar **ArgoCD** para o lado Kubernetes — manifestos em Git, sincronização automática. Já citado como padrão junto com ESO nas Decisões Técnicas.
- `LAB-OPS-03`: Separar o repositório em dois layers: `infra/` (Terraform, gerenciado pelo `waspctl`) e `platform/` (manifestos K8s, gerenciado pelo ArgoCD).

---

### 5.2 — Observabilidade Centralizada (Logging + Alertas)

- `LAB-OPS-04`: Enviar logs do Istio, ALB access logs e logs de aplicação para **CloudWatch Logs**. Habilitar ALB access logs em S3 (gratuito, necessário para análise de segurança e compliance).
- `LAB-OPS-05`: Habilitar **EKS Control Plane Logging** (API, authenticator, audit, scheduler, controller manager). O audit log é obrigatório para produção.
- `LAB-OPS-06`: Criar **CloudWatch Alarms** para: taxa de erro 5xx no ALB > 1%, latência p99 > 2s, número de pods não saudáveis > 0.

---

### 5.3 — Runbooks e Onboarding Automatizado

- `LAB-OPS-07`: Transformar o script de onboarding de tenant em processo idempotente e versionado — candidato natural para `waspctl tenant create` da Fase 2.
- `LAB-OPS-08`: Documentar **runbook de rollback**: como reverter um Helm chart / ArgoCD Application para a revisão anterior.

---

### 5.4 — CI/CD de Imagens de Container

- `LAB-OPS-09`: Implementar pipeline (GitHub Actions ou CodeBuild) que builda as imagens dos três microserviços Python, faz push para **ECR privado** e atualiza o digest fixo nos manifestos Kubernetes.
- `LAB-OPS-10`: Adicionar **Trivy** ou **Grype** no pipeline para scan de vulnerabilidades antes do push para ECR.

---

## 🌱 Pilar 6 — Sustainability

- `LAB-SUS-01`: Configurar Karpenter para preferir instâncias **Graviton3** (`m7g`, `t4g`) nas regiões suportadas — mesma performance, ~20% menos custo e ~60% menos consumo de energia comparado ao x86 equivalente.

---

## Resumo priorizado

| Prioridade | Item(s) | Pilar | Rationale |
|---|---|---|---|
| 🔴 **P0** | `LAB-VPN-01~06` — Control plane privado + WireGuard | Security | API K8s exposta na internet é inaceitável em produção |
| 🔴 **P0** | `LAB-SEC-08` — KMS encryption no etcd | Security | Pré-requisito para qualquer secret sensível no cluster |
| 🔴 **P0** | SEC-006 fix — IMDSv2 obrigatório | Security | Proteção contra SSRF; issue documentada e aberta |
| 🟠 **P1** | `LAB-SEC-09~11` — ESO + Secrets Manager | Security | Elimina secrets de tenant no etcd; habilita rotação |
| 🟠 **P1** | `LAB-SEC-12` — mTLS STRICT entre sidecars | Security | Zero-trust dentro do cluster |
| 🟠 **P1** | `LAB-OPS-01~02` — Terraform + ArgoCD | Ops Excellence | Idempotência e auditabilidade para produção |
| 🟡 **P2** | `LAB-REL-01~03` — Karpenter + PDB + TopologySpread | Reliability | HA real em múltiplas AZs |
| 🟡 **P2** | `LAB-OPS-04~06` — Logging + Alarms | Ops Excellence | Observabilidade mínima para operar |
| 🟡 **P2** | `LAB-PERF-01~02` — Prometheus + Tracing | Performance | Visibilidade para otimização |
| 🟢 **P3** | `LAB-REL-06` — DynamoDB Global Tables | Reliability | Pré-requisito para Fase 3 multi-região |
| 🟢 **P3** | `LAB-COST-01~04` — Spot + Tags + GA scheduling | Cost | Otimização após estabilidade operacional |
| 🟢 **P3** | `LAB-OPS-09~10` — ECR + Trivy | Ops/Security | Supply chain hardening |
| 🟢 **P3** | `LAB-SUS-01` — Graviton3 nodes | Sustainability | Custo e eficiência energética |

---

## Relação com o Roadmap de Fases do waspctl

| Fase | Itens deste documento relacionados |
|---|---|
| Fase 1 (atual) | SEC-002~006 fixes, LAB-VPN-01~06, LAB-SEC-08~12, LAB-OPS-01~02 |
| Fase 2 (platform-cluster separado) | LAB-REL-01~05, LAB-OPS-03~08, LAB-PERF-01~04, LAB-COST-01~04 |
| Fase 3 (multi-região + GA + DynamoDB Global) | LAB-REL-06~09, LAB-SUS-01 |
