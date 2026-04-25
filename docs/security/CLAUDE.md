# security/ — Security

## What lives here

- Consolidated issues index (`index.md`)
- Individual issues linked in `../security-issues/SEC-NNN.md`

## Point issue vs structural change

| Situation | Use |
|---|---|
| Bug/misconfiguration in an existing script or config | Issue in `../security-issues/SEC-NNN.md` |
| Hardening that changes architecture or process | Change in `../well-architected-framework/security/changes/` |
| Fix that closes an existing issue | Change referencing the SEC-NNN in `proposal.md` |

## Opening a new security issue

1. Create `../security-issues/sec-NNN.md` with: severity, attack vector, status
2. Add entry in `index.md`
3. If the fix requires a structural change, create it in
   `../well-architected-framework/security/changes/<name>/`

## Closing an issue

1. Update `status` in `../security-issues/SEC-NNN.md` → `Resolved`
2. Update the row in the table in `index.md`
3. If there was an associated change, archive it (see playbook below)

## Proposing a security change

1. Check `../well-architected-framework/security/changes/` — it may already exist
2. Create `../well-architected-framework/security/changes/<kebab-case-name>/`
   with `proposal.md` and `tasks.md`
3. Reference the related SEC-NNN in `proposal.md`

## Change closing playbook

1. Update status of resolved issues in `../security-issues/` and `index.md`
2. `mv ../well-architected-framework/security/changes/<name> .../archive/YYYY-MM-<name>`
3. Cancelled change: `-cancelled` suffix; note in `proposal.md`

## Severity criteria

| Severity | Criterion |
|---|---|
| High | Direct compromise without additional conditions |
| Medium | Viable vector with additional conditions (SSRF, compromised role) |
| Low | Increased attack surface, mitigated by other layers |
