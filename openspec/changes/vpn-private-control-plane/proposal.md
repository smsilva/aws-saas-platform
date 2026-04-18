# Proposal: VPN — Private EKS Control Plane (WireGuard)

## Problem

The EKS API server endpoint is publicly accessible by default (`eksctl` default: `endpointPublicAccess: true`). Any actor with valid IAM credentials can reach the Kubernetes API from the internet, increasing the blast radius of a compromised IAM identity.

## Proposed Change

Make the EKS control plane endpoint private and provide operator access exclusively through a WireGuard VPN gateway hosted on a small EC2 instance inside the VPC.

```
Operator (laptop)
    │
    │  WireGuard tunnel (UDP 51820)
    ▼
EC2 WireGuard gateway (public subnet, Elastic IP)
    │
    │  VPC-internal routing
    ▼
EKS API endpoint (private, reachable only from VPC CIDR)
```

End-user traffic is unaffected: ALBs and Global Accelerator remain public.

## Why WireGuard

- Kernel module native since Linux 5.6 — no userspace daemon
- Clients available for macOS, Windows, iOS, Android
- Simpler configuration than OpenVPN or AWS Client VPN
- No per-connection cost (unlike AWS Client VPN at ~$0.05/hr per connection)

## Out of Scope

- MFA enforcement on VPN connection (Phase 2)
- Multi-operator key rotation automation (Phase 2)
- AWS Client VPN as an alternative (evaluated and deferred — cost)

## Success Criteria

- `endpointPublicAccess: false` on the cluster
- `kubectl get nodes` fails without the WireGuard tunnel active
- `kubectl get nodes` succeeds with the WireGuard tunnel active
- ALB and platform services remain reachable from the internet during and after the change
