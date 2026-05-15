# docs/ — Memory Bank

## Structure

| Folder | Content |
|---|---|
| `architecture/` | Topology, traffic flow, technical decisions, formal specs |
| `well-architected-framework/` | WAF Roadmap — 17 changes organized by pillar |
| `security/` | Open/closed security issues, reviews; individual issues in `security/issues/` |
| `operations/` | Provisioning step-by-step, scripts 01-17 |
| `services/` | Documentation for the 3 Python/FastAPI microservices |

## Root-level files

| File | Role |
|---|---|
| `README.md` | MkDocs home page — provisioned components overview |
| `technical-decisions.md` | Design decisions, trade-offs, and phase roadmap |
| `multi-tenant-auth-flow.md` | Login flow narrative: Cognito, DynamoDB, JWT isolation |
| `customer-onboarding.md` | Tenant onboarding steps and configuration |

## General rule

Any significant change in any `docs/` folder must be proposed as a change before being executed. See the CLAUDE.md of the target folder.

**Significant change:** reorganization, new thematic area, convention change, document merge or removal.

**Direct fix (no change needed):** typo, value update, new row in an existing table.

## Before any work in docs/

1. Read the CLAUDE.md of the target folder
2. Check `changes/` in progress for that folder
3. Check if there is a formal spec relevant to the topic (in `docs/architecture/` or service docs)

## WAF execution ordering

Changes are ordered P0→P3 with sequential dependencies: P0 must complete before P1, P1 before P2, etc. Check `well-architected-framework/README.md` before proposing or scheduling any change.

## Formal specs

Some WAF changes carry formal specs at `well-architected-framework/<pillar>/changes/<name>/specs/<topic>/spec.md`. Check there before changing architecture or security configuration — specs are more precise than narrative docs.

## Date convention

Always absolute. "Thursday" → "2026-04-24".
