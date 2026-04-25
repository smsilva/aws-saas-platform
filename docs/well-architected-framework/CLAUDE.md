# well-architected-framework/ — Roadmap WAF

## O que vive aqui

Changes de melhoria organizadas pelos 6 pilares do AWS Well-Architected Framework.
Cada change tem `proposal.md`, `tasks.md` e `design.md`.

## Pilares

| Pilar | Diretório | Changes ativas |
|---|---|---|
| 🔐 Security | `security/changes/` | 7 |
| 🏛 Reliability | `reliability/changes/` | 3 |
| ⚡ Performance | `performance/changes/` | 1 |
| 💰 Cost | `cost/changes/` | 1 |
| 🔧 Operations | `operations/changes/` | 4 |
| 🌱 Sustainability | `sustainability/changes/` | 1 |

## Como propor uma change

1. Identificar o pilar pela natureza da mudança
2. Verificar `<pilar>/changes/` — a change pode já existir
3. Verificar `<pilar>/changes/archive/` — pode ter sido tentado antes
4. Criar `<pilar>/changes/<nome-kebab-case>/proposal.md` e `tasks.md`
5. Consultar `index.md` para verificar dependências (ex: P1 requer P0)

## Antes de propor

- `index.md` — ordem de execução e dependências entre as 17 changes
- Changes P0 e P1 bloqueiam as demais; verificar status antes de propor P2+
- Overlap com cost: verificar `cost/changes/tagging-savings-plans/` se envolver tags

## Playbook de fechamento de change

1. Mover conhecimento permanente para `docs/arquitetura/` ou `docs/servicos/`
2. Atualizar `index.md` se a ordem de execução mudar
3. `mv <pilar>/changes/<nome> <pilar>/changes/archive/YYYY-MM-<nome>`
4. Change cancelada: sufixo `-cancelled`; nota em `proposal.md` com motivo