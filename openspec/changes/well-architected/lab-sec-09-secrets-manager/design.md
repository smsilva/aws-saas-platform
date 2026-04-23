# Design: LAB-SEC-09 — AWS Secrets Manager

One secret per tenant under the `wasp/<env>/callback-handler/<tenant-id>` path containing the App Client secret. JWT signing key as a separate secret at `wasp/<env>/callback-handler/state-jwt-secret`.

Path convention:
- `wasp/lab/callback-handler/customer1` → `{ "COGNITO_CLIENT_SECRET_CUSTOMER1": "..." }`
- `wasp/lab/callback-handler/customer2` → `{ "COGNITO_CLIENT_SECRET_CUSTOMER2": "..." }`
- `wasp/lab/callback-handler/state-jwt-secret` → `{ "STATE_JWT_SECRET": "..." }`

**Benefit:** Adding a new tenant requires only adding a new secret — no `kubectl apply` and no `callback-handler` rollout restart.
