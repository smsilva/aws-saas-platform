# AGENTS.md — Project Overview for AI Agents

## What This Is

A multi-tenant SaaS platform lab on AWS EKS. Provisions VPC, EKS cluster,
ALB, Istio service mesh, WAFv2, Cognito (federated IdP hub), DynamoDB, and
three Python microservices implementing a multi-tenant OAuth flow.

**Related:** `waspctl` CLI at `~/git/waspctl` automates this same topology
for Phases 2–3 (multi-region + Global Accelerator).

## Stack

**Infra:** EKS 1.34 · Istio (Gateway + mTLS) · ALB Controller · WAFv2 ·
Global Accelerator · DynamoDB `tenant-registry` · Cognito · Azure DNS

**Services:** Python 3.12 · FastAPI · `discovery`, `platform-frontend`,
`callback-handler` · Docker Hub (tag = git SHA, never `:latest`)

**Automation:** Bash scripts `scripts/01–17` · config in `scripts/env.conf`

**Local lab:** k3d + Keycloak · `lab/aws/eks/local/` · domain `wasp.local`

## Build & Test

```bash
# Python services (run from lab/aws/eks/)
make test                    # all services
make test-callback-handler
make test-discovery
make test-platform-frontend
make test-tenant-frontend

# First-time setup per service
cd lab/aws/eks/services/<service>
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
.venv/bin/pytest tests/ -v --cov

# Docs site
mkdocs serve
```

## Code Standards

- **Never commit directly to `main`** — always branch + PR
- **TDD:** write tests before implementation; maintain 100% coverage on Python services
- **Docker images:** tag = git short SHA, never `:latest`; build with `--platform linux/amd64`
- **Bash scripts:** long-form flags (`--yes` not `-y`), 2-space indent, quote all vars
- **Architectural decisions:** record as ADR in `docs/architecture/architectural-decision-records/`
- **Before refactoring:** check `docs/technical-debts/` for debts in scope

## Documentation

| Location | Content |
|---|---|
| `docs/` | Full documentation index — start here |
| `docs/arquitetura/` | Architecture, traffic flow, formal specs (`*-spec.md`) |
| `docs/well-architected-framework/` | 17 WAF improvement changes organized by pillar |
| `docs/seguranca/` | Security issues index and review |
| `docs/operacoes/` | Provisioning step-by-step (scripts 01–17) |
| `docs/servicos/` | Microservice documentation |
| `docs/decisoes-tecnicas.md` | Design decisions and trade-offs |
| `HANDOFF.md` | Current session state and open tasks |
