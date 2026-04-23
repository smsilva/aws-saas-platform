# Tasks: LAB-SEC-11 — ExternalSecret for callback-handler

## Checklist

- [ ] Write `ExternalSecret` manifest replacing `callback-handler-secret`
- [ ] Deploy and verify: `kubectl get secret -n auth callback-handler-secret` contains all expected keys
- [ ] Test: restart `callback-handler` and confirm login flow works end-to-end
- [ ] Remove manual `kubectl apply` of the old secret from `scripts/13-deploy-services`
