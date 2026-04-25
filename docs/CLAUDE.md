# docs/ — Memory Bank

## Structure

| Folder | Content |
|---|---|
| `arquitetura/` | Topology, traffic flow, technical decisions, formal specs |
| `well-architected-framework/` | WAF Roadmap — 17 changes organized by pillar |
| `seguranca/` | Open/closed security issues, reviews |
| `operacoes/` | Provisioning step-by-step, scripts 01-17 |
| `servicos/` | Documentation for the 3 Python/FastAPI microservices |
| `security-issues/` | Individual issues SEC-NNN (point-in-time, non-structural) |

## General rule

Any significant change in any `docs/` folder must be proposed as a change before being executed. See the CLAUDE.md of the target folder.

**Significant change:** reorganization, new thematic area, convention change, document merge or removal.

**Direct fix (no change needed):** typo, value update, new row in an existing table.

## Before any work in docs/

1. Read the CLAUDE.md of the target folder
2. Check `changes/` in progress for that folder
3. Check if there is a formal spec (`*-spec.md`) relevant to the topic

## Date convention

Always absolute. "Thursday" → "2026-04-24".
