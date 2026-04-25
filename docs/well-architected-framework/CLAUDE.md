# well-architected-framework/ — WAF Roadmap

## What lives here

Improvement changes organized by the 6 AWS Well-Architected Framework pillars.
Each change has `proposal.md`, `tasks.md`, and `design.md`.

## Pillars

| Pillar | Directory | Active changes |
|---|---|---|
| 🔐 Security | `security/changes/` | 7 |
| 🏛 Reliability | `reliability/changes/` | 3 |
| ⚡ Performance | `performance/changes/` | 1 |
| 💰 Cost | `cost/changes/` | 1 |
| 🔧 Operations | `operations/changes/` | 4 |
| 🌱 Sustainability | `sustainability/changes/` | 1 |

## How to propose a change

1. Identify the pillar by the nature of the change
2. Check `<pillar>/changes/` — the change may already exist
3. Check `<pillar>/changes/archive/` — it may have been attempted before
4. Create `<pillar>/changes/<kebab-case-name>/proposal.md` and `tasks.md`
5. Consult `README.md` to verify dependencies (e.g., P1 requires P0)

## Before proposing

- `README.md` — execution order and dependencies between the 17 changes
- P0 and P1 changes block others; verify status before proposing P2+
- Cost overlap: check `cost/changes/tagging-savings-plans/` if tags are involved

## Change closing playbook

1. Move permanent knowledge to `docs/architecture/` or `docs/services/`
2. Update `README.md` if the execution order changes
3. `mv <pillar>/changes/<name> <pillar>/changes/archive/YYYY-MM-<name>`
4. Cancelled change: `-cancelled` suffix; note in `proposal.md` with reason
