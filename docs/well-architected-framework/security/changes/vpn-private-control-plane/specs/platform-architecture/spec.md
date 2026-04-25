# Spec Delta: platform-architecture

## ADDED Requirements

### Private EKS Control Plane Endpoint

The EKS cluster is configured with `endpointPrivateAccess: true` and `endpointPublicAccess: false`. The Kubernetes API server is reachable only from within the VPC CIDR (`10.0.0.0/16`).

### WireGuard VPN for Operator Access

A WireGuard VPN gateway runs on an EC2 instance in a public subnet so that operators can reach the private EKS API endpoint. The gateway:
- Listens on UDP 51820
- Accepts connections only from pre-approved operator IP ranges
- Forwards traffic to the VPC CIDR using split-tunnel routing
- Holds an Elastic IP for a stable client endpoint

Without an active WireGuard tunnel, `kubectl get nodes` times out and never reaches the EKS API server. With the tunnel active, the command succeeds and returns the cluster node list.

Making the EKS control plane endpoint private has no effect on end-user traffic: requests to `wasp.silvios.me` and all tenant subdomains continue to be served normally through the Global Accelerator and ALB.