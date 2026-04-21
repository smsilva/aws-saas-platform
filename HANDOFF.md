# HANDOFF — Ambiente Local com k3d + Terraform AWS

## Terraform AWS — Iniciativa em andamento (2026-04-21)

**Goal:** migrar provisionamento AWS (atualmente bash scripts) para Terraform.

**Escopo:** VPC + EKS cluster + DynamoDB + Cognito + WAF (scripts 01, 02, 09–12).
Kubectl/Helm (scripts 03–08, 13–15) permanecem fora do Terraform por ora.

**Estratégia:** recriar do zero (cluster `wasp-cool-whale-7zr5` será destruído antes).
Sem `terraform import` — fresh state.

**Backend S3:**
- Bucket: `silvios-wasp-foundation` (região `us-west-2`)
- State key: `terraform/aws-saas-platform/wasp.tfstate`

**Referência de variáveis:** `scripts/env.conf` — região, CIDRs, instance types, tags.

---

### Estrutura de diretórios (espelhar `~/git/azure-kubernetes`)

```
terraform/
├── src/                        # módulos reutilizáveis (equivalente a azure-kubernetes/src/)
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   │   ├── main.tf             # usa terraform-aws-modules/eks internamente
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── dynamodb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cognito/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── waf/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/
│   ├── common/                 # arquivos compartilhados via symlink (equivalente a azure-kubernetes/examples/common/)
│   │   ├── create-symbolic-links  # script bash que cria os symlinks nos exemplos
│   │   ├── provider.tf         # backend S3 + provider aws
│   │   └── variables.tf        # variáveis comuns (region, tags, domain, cert_arn)
│   └── lab/                    # exemplo completo do lab
│       ├── main.tf             # locals + módulos vpc/eks/dynamodb/cognito/waf
│       └── outputs.tf
│       # provider.tf e variables.tf são symlinks para common/
└── stack.yaml                  # metadados (nome, versão tf, backend)
```

### Convenções (baseadas no azure-kubernetes)

- **`locals {}`** no `main.tf` do exemplo para valores fixos; não usar `terraform.tfvars` para o lab
- **Módulos referenciados** com `source = "../../src/<modulo>"`
- **`output "instance"`** em cada módulo exporta o recurso inteiro; `output "id"` exporta só o ID
- **`output "kubeconfig"`** (eks) com `sensitive = true`
- **Versões de provider** com ranges: `>= 6.0.0, < 7.0.0`
- **`depends_on`** explícito quando módulos dependem de outros (ex: eks depende de vpc)
- **`count = local.install_X ? 1 : 0`** para recursos opcionais
- Nunca colocar backend no módulo (`src/`) — só nos exemplos via `common/provider.tf`
- Symlinks criados com script `common/create-symbolic-links`; rodar antes do primeiro `terraform init`

#### Convenção de subnets — objetos nomeados

Subnets definidas como lista de objetos `{ cidr, name, az, public }`, permitindo referência por nome no exemplo:

```hcl
# em locals do exemplo
virtual_network_subnets = [
  { cidr = "10.0.1.0/24", name = "public-1a",  az = "us-east-1a", public = true  },
  { cidr = "10.0.2.0/24", name = "public-1b",  az = "us-east-1b", public = true  },
  { cidr = "10.0.3.0/24", name = "private-1a", az = "us-east-1a", public = false },
  { cidr = "10.0.4.0/24", name = "private-1b", az = "us-east-1b", public = false },
]

# referência por nome (output do módulo vpc)
subnet_ids = module.vpc.subnets["private-1a"].id
```

O módulo VPC expõe `output "subnets"` como `map(object)` keyed por `name`.

#### Módulos locais vs. externos

Módulos em `src/` são **locais** por ora — recursos AWS escritos diretamente, sem wrapper de repositório externo (ex: sem `git@github.com:smsilva/aws-network.git`). Extração para repositório separado é trabalho futuro. Módulos do Terraform Registry público (`terraform-aws-modules/eks`) ainda são permitidos onde a complexidade justifica (ex: EKS com OIDC, IAM roles, managed node groups).

### Versões de providers (verificado 2026-04-21)

| Provider / Module | Versão | Constraint |
|---|---|---|
| hashicorp/aws | 6.41.0 | `>= 6.0.0, < 7.0.0` |
| terraform-aws-modules/eks/aws | 21.18.0 | `~> 21.18` |
| hashicorp/archive | latest 2.x | `>= 2.0.0, < 3.0.0` |

> `terraform-aws-modules/vpc` **não será usado** — módulo VPC escrito localmente para suportar a convenção de subnets nomeadas.

### Plano incremental (etapas sequenciais)

Cada etapa termina com `terraform validate` (ou apply+destroy) antes de avançar.

#### Etapa 1 — Scaffold ✅
Criar estrutura de diretórios + arquivos de metadados raiz. Sem código Terraform ainda.
- `terraform/stack.yaml` — nome, versão tf, config backend S3
- `terraform/cz.yaml` — commitizen (espelhar `azure-kubernetes/cz.yaml`)
- `terraform/examples/lab/backend.conf` — parâmetros S3 para `tfi` (`--backend-config`); ignorado pelo `.gitignore`
- Pastas vazias: `src/{vpc,eks,dynamodb,cognito,waf}/` e `examples/{common,lab}/`

#### Etapa 2 — Common provider + symlinks ✅
Criar config compartilhada de provider, usada via symlink por todos os exemplos.
- `examples/common/provider.tf` — backend S3 + providers aws/archive
- `examples/common/variables.tf` — region, domain, cert_arn, tags, google_client_id (sensitive), google_client_secret (sensitive)
- `examples/common/create-symbolic-links` — script bash que cria symlinks nos exemplos

#### Etapa 3 — Módulo VPC (recursos locais + subnets nomeadas) ✅
Módulo escrito diretamente com recursos AWS — sem wrapper de módulo externo.
- `src/vpc/main.tf` — `aws_vpc`, `aws_subnet` (for_each em `var.subnets`), `aws_internet_gateway`, `aws_eip`, `aws_nat_gateway` (em subnet pública com menor índice), `aws_route_table` (public + private), `aws_route_table_association`; EKS subnet tags (elb / internal-elb / cluster owned)
- `src/vpc/variables.tf` — `name`, `cidr`, `subnets` (list of `{ cidr, name, availability_zone, public }`), `tags`
- `src/vpc/outputs.tf` — `id` (vpc_id), `instance` (aws_vpc), `subnets` (map keyed by name → `{ id, instance }`), `public_subnet_ids`, `private_subnet_ids`

**Decisões tomadas:**
- Campo `az` renomeado para `availability_zone` para clareza
- `cluster_name` removido — EKS subnet tags usam `var.name` (VPC e cluster compartilham o mesmo nome)
- `var.domain` e `var.cert_arn` têm defaults com valores do lab para não exigir `-var` no `terraform plan`

#### Etapa 4 — Exemplo lab (checkpoint validate+plan) ✅
- `examples/lab/main.tf` — locals com valores fixos + `module "vpc"`
- `examples/lab/outputs.tf` — vpc_id, public_subnet_ids, private_subnet_ids
- `provider.tf` e `variables.tf` são symlinks para `common/`
- `terraform validate` ✅ e `terraform plan` ✅ — 16 recursos planejados
- `apply` + `destroy` **pendentes** — deixados para quando EKS estiver pronto (Etapa 5)

#### Makefile ✅
- `terraform/Makefile` — targets `init`, `plan`, `apply`, `destroy` com `-chdir=examples/lab` e `-backend-config=backend.conf`

#### Etapa 5 — Módulo EKS ✅
Usa `terraform-aws-modules/eks ~> 21.18` internamente (complexidade de IAM/OIDC justifica).
- `src/eks/main.tf` — wraps `terraform-aws-modules/eks/aws ~> 21.18`; `endpoint_public_access=true`; node group nas subnets privadas; local `kubeconfig` gerado com `aws eks get-token`
- `src/eks/variables.tf` — name, cluster_version, vpc_id, subnet_ids, private_subnet_ids, node_instance_type, node_min_count/max_count/desired_count, tags
- `src/eks/outputs.tf` — id, instance (sensitive), cluster_name, cluster_endpoint, oidc_provider_arn, kubeconfig (sensitive)
- `examples/lab/main.tf` — local.name adicionado; module "vpc" usa local.name; module "eks" adicionado (sem depends_on — dependência já expressa pelos argumentos)
- `examples/lab/outputs.tf` — cluster_name, cluster_endpoint, oidc_provider_arn adicionados
- `terraform validate` ✅ e `terraform plan` ✅ — **49 recursos planejados** (16 VPC + 33 EKS)
- `apply` + `destroy` pendentes — executar quando pronto para provisionar o cluster real

**Decisões tomadas (Etapa 5):**
- `terraform-aws-modules/eks` v21 usa `name` (não `cluster_name`), `kubernetes_version` (não `cluster_version`), `endpoint_public_access` (não `cluster_endpoint_public_access`)
- `depends_on = [module.vpc]` removido do `module "eks"` — causava "count depends on unknown values" durante plan; dependência já implícita pelos argumentos `vpc_id` e `subnet_ids`
- `data.aws_region.current.id` em vez de `.name` (deprecated no provider v6)
- Variáveis de contagem de nodes usam `_count` (não `_size`) para consistência com o projeto

**Próximo passo:** Etapa 6 — Módulo DynamoDB

#### Etapa 6 — Módulo DynamoDB ✅
- `src/dynamodb/main.tf` — `aws_dynamodb_table` PROVISIONED; `dynamic "attribute"` para lista de campos; `dynamic "global_secondary_index"` com `key_schema` block interno (API não deprecated do provider v6)
- `src/dynamodb/variables.tf` — `table_name`, `hash_key`, `attributes` (list `{name, type}`), `global_secondary_indexes` (list com opcionais: `projection_type`, `read_capacity`, `write_capacity`), `read_capacity`, `write_capacity`, `tags`
- `src/dynamodb/outputs.tf` — `id`, `arn`, `instance`
- `examples/lab/main.tf` — `module "dynamodb"` com `tenant-registry`, pk `pk`, GSI `client-id-index` em `cognito_app_client_id`
- `terraform validate` ✅ e `terraform plan` ✅ — **50 recursos planejados** (49 anteriores + 1 DynamoDB)

**Decisões tomadas (Etapa 6):**
- `global_secondary_index.hash_key` deprecated no provider v6 — substituído por bloco `key_schema { attribute_name, key_type }` internamente; interface da variável mantém `hash_key` string para simplicidade
- `global_secondary_indexes` como lista (default `[]`) é a "variável que indica se vai ter index" — lista vazia = sem GSI
- Recurso nomeado `default` (convenção do projeto, não `this`)
- `attributes` como lista de objetos `{name, type}` permite declarar todos os atributos usados em índices no exemplo

**Próximo passo:** Etapa 7 — Módulo Cognito

#### Etapa 7 — Módulo Cognito ✅

**Arquitetura:** Lambda compartilhada (`src/cognito/`) + User Pool por tenant (`src/cognito/userpool/`).

**`src/cognito/`** — cria a Lambda compartilhada e expõe o ARN:
- `lambda/lambda_function.py` — pre-token generation; consulta DynamoDB GSI `client-id-index` via `cognito_app_client_id` e injeta `custom:tenant_id`
- `iam.tf` — IAM role + `AWSLambdaBasicExecutionRole` + policy inline `dynamodb:Query` no GSI
- `lambda.tf` — `archive_file` (zip) + `aws_lambda_function`; env var `DYNAMODB_TABLE`
- `variables.tf` — `name`, `dynamodb_table_name`, `dynamodb_table_arn`, `tags`
- `outputs.tf` — `lambda_arn`

**`src/cognito/userpool/`** — módulo standalone; uma instância por tenant:
- `main.tf` — `locals` (idp_name derivado, callback/logout URLs com defaults), `aws_cognito_user_pool` (schema `custom:tenant_id`, trigger `pre_token_generation`), `aws_lambda_permission` com `statement_id` único por tenant
- `idp.tf` — `aws_cognito_identity_provider` Google (`count = idp_type=="google"`) e Microsoft OIDC (`count = idp_type=="microsoft"`); nome derivado: `Google-${title(tenant)}` / `MicrosoftAD-${title(tenant)}`
- `client.tf` — `aws_cognito_user_pool_client` com `for_each`-ready interface; `supported_identity_providers` dinâmico
- `variables.tf` — `tenant`, `name`, `domain`, `lambda_arn`, `idp_type` (validado), `idp_client_id/secret` (sensitive), `idp_oidc_issuer` (default Microsoft personal), `callback_urls`, `logout_urls`, `tags`
- `outputs.tf` — `user_pool_id`, `user_pool_arn`, `app_client_id`, `instance` (sensitive)

**`examples/lab/main.tf`** — `module "cognito"` + `module "userpool_customer1"`; outputs `cognito_lambda_arn`, `customer1_user_pool_id`, `customer1_app_client_id`

**`terraform validate` ✅ e `terraform plan` ✅ — 58 recursos planejados** (50 anteriores + 8 Cognito)

**Decisões tomadas (Etapa 7):**
- Lambda compartilhada (`src/cognito/`) separada dos User Pools (`src/cognito/userpool/`) — evita duplicar Lambda + IAM por tenant
- `aws_lambda_permission.statement_id = "CognitoPreTokenGeneration-${var.tenant}"` — evita conflito quando múltiplos pools referenciam a mesma Lambda
- `idp_type` com `validation` block — falha rápido em valores inválidos
- `idp_name` local no `main.tf` do userpool — compartilhado entre `idp.tf` e `client.tf`
- `callback_urls`/`logout_urls` com defaults derivados de `var.domain` e `var.tenant` — não exige sobrescrever para o caso padrão
- Nomenclatura no exemplo: `userpool_customer1` (não `customer1_userpool`) — consistência com prefixo do tipo de recurso

**Próximo passo:** Etapa 8 — Módulo WAF

#### Etapa 8 — Módulo WAF
- `src/waf/main.tf` — `aws_wafv2_web_acl` REGIONAL; 3 managed rules (CommonRuleSet p1, KnownBadInputs p2, IpReputation p3); associação ALB opcional (`count = var.alb_arn != "" ? 1 : 0`)
- `src/waf/variables.tf` — name, alb_arn (default ""), tags
- `src/waf/outputs.tf` — id, instance, arn
- Atualizar exemplo: adicionar module "waf"
- `terraform validate` + `terraform plan` final completo

---

## Goal

`local/` — versão offline do lab AWS EKS usando k3d, sem dependências de cloud.
Permite desenvolver e testar os serviços Python localmente sem AWS.

## Current Progress

**Lab local: completo e validado end-to-end.**

| Script | Status |
|---|---|
| `env.conf` | ✅ |
| `bootstrap` | ✅ |
| `01-create-cluster` | ✅ |
| `02-install-haproxy-ingress` | ✅ |
| `03-install-cert-manager` | ✅ |
| `04-install-istio` | ✅ |
| `05-deploy-keycloak` | ✅ |
| `06-deploy-services` | ✅ |
| `07-configure-istio-auth` | ✅ |
| `08-deploy-customer2` | ✅ |
| `destroy` | ✅ |
| `docs/diferencas-aws.md` | ✅ |
| `docs/lessons-learned.md` | ✅ |

**Serviços modificados (TDD, AWS intacto):**

| Serviço | Mudança |
|---|---|
| `discovery` | `SQLiteTenantRepository` + `BACKEND=sqlite\|dynamodb` (default `dynamodb`) + `SQLITE_SEED_FILE` |
| `platform-frontend` | `IDP_AUTHORIZE_URL` opcional; `identity_provider` omitido quando `idp_name=""`; `tenant_url` usado as-is quando já tem scheme |
| `callback-handler` | `IDP_TOKEN_URL` opcional; `COOKIE_SECURE` e `COOKIE_DOMAIN` configuráveis por env var |
| `tenant-frontend` | `IDP_LOGOUT_URL` e `LOGOUT_CALLBACK_URL` configuráveis; logout com IdP redirect + `/logout/callback` |

**Testes:** 16 (platform-frontend) + 34 (discovery) + 26 (callback-handler) + 38 (tenant-frontend) = 114 passando.

**Fluxo end-to-end validado:**

```
POST /login (user1@customer1.com)
  → 302 → Keycloak login page
  → POST credentials
  → 302 → /callback?code=...&state=...
  → 302 → customer1.wasp.local:32080 + set-cookie: session=<JWT>
  → 200 customer1 com JWT              ← custom:tenant_id=customer1 ✅
  → 403 customer2 com JWT customer1    ← isolamento Istio ✅
  → 403 customer2 sem JWT              ← Istio AuthorizationPolicy ✅
```

## What Worked

- HAProxy Ingress em vez de Nginx (deprecated) — `NodePort 32080`
- Keycloak oficial `quay.io/keycloak/keycloak:26.1` com `start-dev` + `k3d image import`
- `frontendUrl` configurado via `PUT /admin/realms/{realm}` com `{"attributes":{"frontendUrl":"..."}}` (não no body de criação)
- User Profile KC 26: declarar `tenant_id` antes de criar usuários, via `GET/PUT /users/profile`
- `VERIFY_PROFILE` desabilitado com `enabled:false` (não apenas `defaultAction:false`)
- `IDP_TOKEN_URL` apontando para service interno do cluster (`keycloak.keycloak.svc.cluster.local:8080`) — evita round-trip pelo HAProxy
- Ingress catch-all em `istio-ingress` com `defaultBackend → istio-ingressgateway:80` — conecta HAProxy ao Istio
- `emptyDir` em `/data` no discovery para o SQLite criar o arquivo `.db`
- `DISCOVERY_URL` in-cluster (`discovery.discovery.svc.cluster.local:8000`) — DNS do `/etc/hosts` não propaga para pods
- `COOKIE_SECURE=false` + `COOKIE_DOMAIN=.wasp.local` — cookie enviado em HTTP com domínio correto
- **namespace `shared` para recursos regionais compartilhados** — `httpbin.wasp.local` movido para `shared` (sem `AuthorizationPolicy`); httpbin permanece nos namespaces de tenant para testes de isolamento via `/httpbin/get`

### Design Decisions (arquitetura)

| Decisão | Implementação |
|---------|---------------|
| **Tenant por `custom:tenant_id`** | Protocol Mapper no Keycloak injeta claim `custom:tenant_id` no token. Isolamento via Istio `AuthorizationPolicy` que valida `request.auth.claims[custom:tenant_id] == tenant_id`. |
| **Naming de secrets multi-tenant** | `IDP_CLIENT_SECRET_<TENANT_ID>` (ex: `IDP_CLIENT_SECRET_CUSTOMER1`). Permite lookup dinâmico no `callback-handler` sem hardcode. |
| **Backend discovery switchável** | `BACKEND=sqlite\|dynamodb` — SQLite para local, DynamoDB para AWS. Default `dynamodb` para compatibilidade. |
| **Claims via User Profile** | `tenant_id` declarado no KC 26 User Profile antes de criar usuários. KC descarta atributos não declarados silenciosamente. |
| **`env.secrets` como fonte única** | Secrets geradas em runtime (`KEYCLOAK_CLIENT_SECRET`, `STATE_JWT_SECRET`) persistidas em `env.secrets` para sessões futuras não regenerarem valores inconsistentes. |

## What Didn't Work / Gotchas

Os gotchas detalhados com soluções estão em `local/docs/lessons-learned.md`. Resumo dos não óbvios:

- **`rollout restart` necessário quando Secret/ConfigMap muda** — sem troca de imagem, pods não remontam env vars automaticamente. `kubectl rollout restart deployment/<name>`.
- **`docker build` manual quebra o CSS compartilhado** — `app/static/shared` é symlink para `../../../../design/shared`. Docker não segue symlinks fora do build context. Sempre substituir o symlink por cópia real antes do build e restaurar depois (ver `_inject_shared`/`_restore_shared` em `06-deploy-services`). Nunca rodar `docker build` diretamente nos serviços de frontend.
- **Subagente sem permissão bash** — subagentes via Agent tool não herdam permissões da sessão principal. Reiniciar o Claude Code ou rodar scripts manualmente.
- **`--skip-schema-validation` inválido em Helm v3.12** — causa `Error: unknown flag`; removida do `04-install-istio`.
- **CORS regex `\.` em YAML dentro de `<<EOF` bash** — `\\.` vira `\.`, escape inválido em YAML. Usar `[.]` no lugar de `\.` nos scripts.
- **Endpoint do discovery é `/tenant?domain=<email_domain>`** — não `/tenants` (404).

## Backlog

### P1 — Quick wins

- [x] **Script de seleção de MCPs por sessão**: `mcp-select` em `~/git/linux/scripts/bin/`. Lê `.mcp.json` do CWD, apresenta menu fzf multi-select com os servers atuais, e reescreve os campos `disabled` no arquivo. Uso: `mcp-select` (antes de invocar o claude).
- [ ] **Script `add-tenant` para lab local** (k3d): análogo ao `configure-idps` AWS, mas para Keycloak — adiciona client + usuário + registro SQLite para um novo tenant sem recriar tudo. Hoje o `08-deploy-customer2` faz isso de forma hardcoded; tornar genérico quando necessário adicionar customer3+.
- [ ] **Decode JWT na página de teste**: `test.html` exibir claims decodificados do JWT (header + payload) ao lado do token bruto.
- [ ] **Screenshots para documentação**: tirar prints das telas principais (login, redirecionamento, página do tenant, isolamento 403) para enriquecer `docs/`.

### P1 — Compatibilidade Cognito (logout)

- [ ] **Parametrizar nome do param de redirect no logout** (`tenant-frontend`): o código usa `post_logout_redirect_uri` (Keycloak/OIDC). O Cognito usa `logout_uri`. Quando ativar `IDP_LOGOUT_URL` nos scripts AWS, será necessário adicionar uma env var `IDP_LOGOUT_REDIRECT_PARAM` (default `post_logout_redirect_uri`; Cognito usa `logout_uri`) e remover `id_token_hint` do fluxo Cognito.

### P2 — Melhorias importantes

- [ ] **Nomes estáveis para recursos de rede**: avaliar usar `cluster_name` fixo em `env.conf` (ex: `wasp-eks-lab`) para VPC/subnets com nome estável entre sessões.
- [ ] **Health check dedicado `/healthz`**: separar tráfego de health check (ALB) do tráfego real; avaliar se expõe risco de segurança.
- [ ] **Redirect ao expirar token**: Istio retorna 403 puro quando JWT expira. O `tenant-frontend` deve detectar expiração (claim `exp`) e redirecionar para `/login`. Alternativa: configurar Istio para redirecionar em vez de 403.
- [ ] **Network policy isolando namespaces**: complementar o isolamento do Istio com `NetworkPolicy` K8s bloqueando tráfego direto entre namespaces de tenants.
- [ ] **Diagrama do Lab EKS**: atualizar `docs/` com diagrama de arquitetura (fluxo de tráfego, componentes, namespaces).
- [ ] **Métricas com OpenTelemetry**: instrumentar os serviços Python para emitir métricas via OTEL (latência, erros, requisições por tenant).
- [ ] **Fitness function / Business metrics**: endpoint de saúde semântica do cluster (ex: `/healthz/business`) com métricas de tenants ativos, autenticações bem-sucedidas, disponível localmente com indicador visual.
- [ ] **Métricas do cluster**: Prometheus + Grafana ou similar para observabilidade de infra (CPU, memória, pods por namespace).
- [ ] **Teste de interface local (e2e)**: testes automatizados de browser para o fluxo de login completo (Playwright ou similar), rodando contra k3d.

### P3 — Exploração / futuro

- [ ] **CDN para assets frontend**: CSS, logo, JS duplicados entre serviços. Avaliar S3+CloudFront ou nginx estático compartilhado.
- [ ] **Cilium CNI em ENI mode**: provisionar EKS com Cilium em vez de AWS VPC CNI.
- [ ] **Istio Ambient Mesh**: implementar e verificar limitações.
- [ ] **Remover `COGNITO_CLIENT_ID` órfão dos ConfigMaps** (AWS): serviços não usam essa variável (vem do discovery via state JWT).
- [ ] **SSM Parameter Store**: migrar secrets de `env.secrets` para SSM (alternativa gratuita ao Secrets Manager).
- [ ] **waspctl network proxy**: comando para provisionar cluster e integrar ao Global Accelerator.
- [ ] **Resource quotas por namespace**: limitar CPU/memória por tenant para evitar noisy neighbor.
- [ ] **Proteger repositório GitHub**: branch protection rules, required reviews, signed commits.
- [ ] **Penetration test**: avaliar OWASP ZAP ou similar contra o lab local (k3d) antes de rodar contra AWS.
- [ ] **CSPM** (Cloud Security Posture Management): avaliar ferramenta para detectar misconfigurações na conta AWS (ex: Prowler, AWS Security Hub).
- [ ] **CIEM** (Cloud Infrastructure Entitlement Management): auditar permissões IAM excessivas; avaliar ferramentas dedicadas.
- [ ] **CNAPP** (Cloud Native Application Protection Platform): avaliar solução unificada que cubra CSPM + CIEM + runtime security (ex: Wiz, Lacework).
- [ ] **Simulação waspctl com IA**: interação conversacional simulando comandos `waspctl` com respostas simuladas, para exercitar conceitos e documentar o fluxo esperado da CLI.


## Key Files

| Arquivo | Relevância |
|---|---|
| `local/scripts/env.conf` | Config global do lab local (domínio, portas, credenciais Keycloak) |
| `local/scripts/env.secrets` | Gerado em runtime — `KEYCLOAK_CLIENT_SECRET`, `STATE_JWT_SECRET` |
| `local/docs/diferencas-aws.md` | Mapa completo de substituições locais |
| `local/docs/lessons-learned.md` | Todos os problemas encontrados e soluções durante execução |
| `scripts/13-deploy-services` | Referência original para o `06-deploy-services` local |
| `scripts/14-configure-istio-auth` | Referência original para o `07-configure-istio-auth` local |
| `CLAUDE.md` | Contexto do lab AWS (domínios, credenciais, regras de TDD) |

## Context

- Diretório local: `local/` (junto aos serviços, coexiste com `scripts/`)
- Domínio local: `wasp.local` (porta `32080` para acesso externo)
- `/etc/hosts`: `127.0.0.1` para `wasp.local`, `auth.wasp.local`, `discovery.wasp.local`, `idp.wasp.local`, `customer1.wasp.local`, `customer2.wasp.local`
- customer1 e customer2 usam o mesmo client Keycloak (`wasp-platform`) — isolamento via `custom:tenant_id`
- Regra do projeto: TDD — testes antes de qualquer alteração nos serviços

## Referências externas

- [smsilva.github.io/aws-saas-platform](https://smsilva.github.io/aws-saas-platform) — documentação publicada do projeto
- [Building a Multi-Tenant SaaS Solution Using Amazon EKS](https://aws.amazon.com/pt/blogs/apn/building-a-multi-tenant-saas-solution-using-amazon-eks) — referência de arquitetura multi-tenant
- [Operating a multi-regional stateless application using Amazon EKS](https://aws.amazon.com/pt/blogs/containers/operating-a-multi-regional-stateless-application-using-amazon-eks) — referência para expansão multi-região
