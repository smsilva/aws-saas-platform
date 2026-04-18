# Spec Delta: platform-architecture

## ADDED Requirements

### Requirement: Private EKS Control Plane Endpoint

The system SHALL configure the EKS cluster with `endpointPrivateAccess: true` and `endpointPublicAccess: false`. The Kubernetes API server SHALL be reachable only from within the VPC CIDR (`10.0.0.0/16`).

### Requirement: WireGuard VPN for Operator Access

The system SHALL provide a WireGuard VPN gateway on an EC2 instance in a public subnet so that operators can reach the private EKS API endpoint. The gateway SHALL:
- Listen on UDP 51820
- Accept connections only from pre-approved operator IP ranges
- Forward traffic to the VPC CIDR using split-tunnel routing
- Hold an Elastic IP for a stable client endpoint

#### Scenario: kubectl without VPN

WHEN an operator runs `kubectl get nodes` without an active WireGuard tunnel
THEN the connection SHALL time out and not reach the EKS API server

#### Scenario: kubectl with VPN

WHEN an operator activates the WireGuard tunnel
THEN `kubectl get nodes` SHALL succeed and return the cluster node list

#### Scenario: End-user traffic is unaffected

WHEN the EKS control plane endpoint is made private
THEN requests to `wasp.silvios.me` and all tenant subdomains SHALL continue to be served normally through the Global Accelerator and ALB
