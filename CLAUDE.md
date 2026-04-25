# CLAUDE.md

## Identifiers

| Resource | Value |
|---|---|
| EKS Cluster | `wasp-cool-whale-7zr5` |
| Region | `us-east-1` |
| AWS Account | `221047292361` |
| Domain | `wasp.silvios.me` (wildcard `*.wasp.silvios.me`) |
| ACM Cert ARN | `arn:aws:acm:us-east-1:221047292361:certificate/3b83625c-895c-461d-a18e-571166508123` |

## Stack

**Infra:** EKS 1.34 · Istio (Gateway + mTLS) · ALB Controller · WAFv2 · Global Accelerator · DynamoDB `tenant-registry` · Cognito (federated IdP hub) · Azure DNS (`wasp.silvios.me`)

**Services:** Python 3.12 · FastAPI · 3 microservices (`discovery`, `platform-frontend`, `callback-handler`) · Docker Hub (tag = git SHA, never `:latest`)

**Automation:** Bash scripts `01–17` in `scripts/` · config in `scripts/env.conf` · `waspctl` CLI at `~/git/waspctl` (Phases 2–3)

**Local lab:** k3d + Keycloak · `lab/aws/eks/local/` · domain `wasp.local`

## Traffic flow

```
Internet → ALB (TLS/ACM) → WAF → Istio IngressGateway (ClusterIP) → VirtualService → App (sidecar)
```

## Essential commands

```bash
./scripts/bootstrap --create    # validate prereqs before provisioning
./scripts/bootstrap --destroy   # validate prereqs before teardown

make test                       # all Python services (from lab/aws/eks/)
make test-<service>             # individual service

mkdocs serve                    # docs site (from repo root)

kubectl get pods -A
helm list -A
```

## Rules

- **Nunca commitar diretamente em `main`** — sempre branch + PR
- **Antes de qualquer refatoração:** verificar `docs/technical-debts/` para débitos documentados no escopo
- **Decisões arquiteturais:** registrar como ADR em `docs/architecture/architectural-decision-records/`
- **Novo recurso AWS/Azure:** adicionar entrada de deleção em `scripts/destroy` na mesma sessão, em ordem reversa com respeito a dependências
- **Design ↔ Services:** mudanças em `lab/aws/eks/design` e `lab/aws/eks/services` devem sempre ser sincronizadas
- **Código de serviço:** cobrir com testes antes (TDD, Pytest + Coverage)
- **HANDOFF.md:** atualizar ao executar scripts de lab — registrar decisões, problemas e soluções

## Imports

@docs/CLAUDE.md
@docs/arquitetura/CLAUDE.md
@docs/well-architected-framework/CLAUDE.md
@docs/seguranca/CLAUDE.md
