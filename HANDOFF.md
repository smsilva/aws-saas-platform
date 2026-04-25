# HANDOFF — aws-saas-platform

## Estado atual (2026-04-22)

**Recursos AWS:** todos destruídos. Estado limpo.
**Branch ativa:** `dev`

---

## Terraform — módulos implementados

Todos os módulos em `terraform/src/` estão completos e validados (`terraform validate` ✅).

| Módulo | Recursos criados |
|---|---|
| `src/vpc` | VPC, subnets (nomeadas), IGW, NAT GW, route tables, EKS subnet tags |
| `src/eks` | EKS cluster (via `terraform-aws-modules/eks ~> 21.18`), managed node group, OIDC, Pod Identity (vpc-cni) |
| `src/dynamodb` | DynamoDB PROVISIONED, GSI, seed items |
| `src/cognito` | Lambda pre-token-generation (compartilhada) + IAM |
| `src/cognito/userpool` | User Pool por tenant, IdP (Google/Microsoft), App Client |
| `src/waf` | WAFv2 REGIONAL, 3 managed rules, associação ALB opcional |

**Exemplo:** `terraform/examples/lab/` — instância completa do lab (VPC + EKS + DynamoDB + Cognito + WAF).  
**Backend S3:** bucket `silvios-wasp-foundation` (us-west-2), key `terraform/aws-saas-platform/wasp.tfstate`.

### Gaps corrigidos (sessão 2026-04-22 — comparação bash vs Terraform)

Script `scripts/capture-metadata` criado para capturar metadados reais de clusters EKS (JSON por recurso em `docs/metadata-<source>/`). Diff completo em `docs/metadata-diff.md`.

| Gap | Fix | Commit |
|---|---|---|
| Disco: default AMI ~20GB gp2 vs 80GB gp3 | `block_device_mappings` (gp3, 80GB, IOPS 3000, throughput 125) | `8acb8fc` |
| SSO admin role ausente como access entry | Variável `access_entries` no módulo; SSO role em `examples/lab/main.tf` | `b967e2c` |
| `metrics-server` addon ausente | Adicionado ao default de `var.addons` | `3de012c` |
| `maxUnavailablePercentage=33` (0 slots com 2 nodes) | `update_config { max_unavailable = 1 }` (absoluto) | `3de012c` |
| vpc-cni sem Pod Identity | IAM role + `pod_identity_association`; `eks-pod-identity-agent` addon | `b5249b3` |

**Gap adiado conscientemente:** `node_min_count = 1` (bash usa 2) — mantido para economizar custo no lab.

### Gotchas importantes (não repita esses erros)

- **`terraform-aws-modules/eks` v21 usa `name`, `kubernetes_version`, `endpoint_public_access`** — não `cluster_name`, `cluster_version`, `cluster_endpoint_public_access`
- **`depends_on = [module.vpc]` no módulo EKS causa "count depends on unknown values"** — remover; dependência já implícita pelos argumentos `vpc_id`/`subnet_ids`
- **`bootstrap_self_managed_addons = false`** (hardcoded no módulo v21) — sem a variável `addons` definida, a AWS não instala vpc-cni/kube-proxy/coredns automaticamente. Nodes ficam em `NetworkUnavailable`.
- **`http_put_response_hop_limit = 1` com IMDSv2 quebra o bootstrap AL2023** — `nodeadm` não alcança o IMDS. Usar `hop_limit = 2`.
- **`attach_cluster_primary_security_group = false` (default)** — nodes não conseguem atingir o endpoint privado do EKS na porta 443. Setar `true`.
- **Cognito `provider_name` para Google deve ser exatamente `"Google"`** — qualquer sufixo causa erro na criação do IdP.
- **`global_secondary_index.hash_key` deprecated no provider v6** — usar bloco `key_schema { attribute_name, key_type }`.

---

## Lab local (k3d)

Completo e validado end-to-end em `local/`. Fluxo de autenticação multi-tenant com Keycloak funcionando.

**Serviços modificados vs AWS** (todos com testes — 114 passando):

| Serviço | Mudança principal |
|---|---|
| `discovery` | `SQLiteTenantRepository` + `BACKEND=sqlite\|dynamodb` |
| `platform-frontend` | `IDP_AUTHORIZE_URL` opcional; `identity_provider` omitido quando `idp_name=""` |
| `callback-handler` | `IDP_TOKEN_URL`, `COOKIE_SECURE`, `COOKIE_DOMAIN` configuráveis |
| `tenant-frontend` | `IDP_LOGOUT_URL`, `LOGOUT_CALLBACK_URL`, `IDP_LOGOUT_REDIRECT_PARAM` configuráveis; logout com IdP redirect |

**Gotchas locais:** ver `local/docs/lessons-learned.md`.

---

## Backlog

### P2

- [ ] **Redirect ao expirar token**: Istio retorna 403 puro — `tenant-frontend` deve detectar expiração (`exp`) e redirecionar para `/login`.
- [ ] **Network policy isolando namespaces**: complementar isolamento Istio com `NetworkPolicy` K8s.
- [ ] **Métricas com OpenTelemetry**: instrumentar serviços Python (latência, erros, requisições por tenant).
- [ ] **Teste e2e local**: Playwright contra k3d cobrindo o fluxo de login completo.
- [ ] **Health check dedicado `/healthz`**: separar tráfego health check (ALB) do tráfego real.

### P3

- [ ] **Cilium CNI em ENI mode**: provisionar EKS com Cilium em vez de AWS VPC CNI.
- [ ] **Istio Ambient Mesh**: implementar e verificar limitações.
- [ ] **SSM Parameter Store**: migrar secrets de `env.secrets` para SSM.
- [ ] **Resource quotas por namespace**: limitar CPU/memória por tenant (noisy neighbor).
- [ ] **CSPM/CIEM/CNAPP**: avaliar Prowler, AWS Security Hub ou solução unificada.
- [ ] **Proteger repositório GitHub**: branch protection rules, required reviews, signed commits.

---

## Referências

| Documento | Conteúdo |
|---|---|
| `docs/metadata-diff.md` | Diff completo bash vs Terraform (campos críticos EKS) |
| `local/docs/lessons-learned.md` | Gotchas do lab local k3d |
| `docs/technical-decisions.md` | Decisões de design e trade-offs |
| `CLAUDE.md` | Contexto operacional (domínios, credenciais, regras TDD) |

- [Building a Multi-Tenant SaaS Solution Using Amazon EKS](https://aws.amazon.com/pt/blogs/apn/building-a-multi-tenant-saas-solution-using-amazon-eks)
- [Operating a multi-regional stateless application using Amazon EKS](https://aws.amazon.com/pt/blogs/containers/operating-a-multi-regional-stateless-application-using-amazon-eks)
