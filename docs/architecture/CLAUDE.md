# architecture/ — Architecture Documentation

## What lives here

- Topology and traffic flow (`index.md`, `traffic-flow.md`)
- Formal component specs — natural language requirements documents
- Links to `../technical-decisions.md` and `../multi-tenant-auth-flow.md`

## How to propose a change

1. Create `architecture/changes/<kebab-case-name>/proposal.md` and `tasks.md`
2. Check `changes/` first — avoid duplication
3. Check `changes/archive/` to understand previous decisions

## ADR vs change

| Situation | Use |
|---|---|
| Design decision taken, needs to be recorded | Entry in `../technical-decisions.md` |
| Architecture change requiring implementation | Change in `changes/` |
| Topology, routing, or traffic flow alteration | Change in `changes/` |
| Diagram update for an already-executed change | Direct edit (no change) |

## Change closing playbook

1. Move permanent knowledge to:
   - `index.md` or `traffic-flow.md` (topology/routing)
   - `../technical-decisions.md` (design decision)
   - corresponding spec file (formal requirement)
2. `mv changes/<name> changes/archive/YYYY-MM-<name>`
3. Cancelled change: move to archive with `-cancelled` suffix; add note in `proposal.md` explaining the reason

## Formal specs

Contain natural language requirements descriptions. They are more precise than narrative documentation. When changing architecture, update the corresponding spec.
