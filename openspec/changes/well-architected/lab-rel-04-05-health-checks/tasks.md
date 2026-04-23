# Tasks: LAB-REL-04~05 — Health Probes and Circuit Breaking

## Checklist

- [ ] Audit all Deployments: confirm `livenessProbe` and `readinessProbe` are present
- [ ] Add missing probes to any Deployment that lacks them
- [ ] Add Istio `DestinationRule` with `outlierDetection` for `discovery`
- [ ] Add Istio `DestinationRule` with `outlierDetection` for `callback-handler`
