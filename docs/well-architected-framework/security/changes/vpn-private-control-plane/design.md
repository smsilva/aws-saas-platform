# Design: VPN — Private EKS Control Plane

## Architecture

```
Operator laptop
  └── wg0 interface (10.8.0.2/24)
        │  UDP 51820 → EIP of EC2 gateway
        ▼
EC2 t3.micro (us-east-1, public subnet)
  ├── eth0: public IP (EIP)
  ├── wg0: 10.8.0.1/24
  └── IP forwarding enabled → routes 10.0.0.0/16 to VPC
        │
        ▼  VPC internal
EKS API endpoint (private DNS, VPC CIDR only)
```

## LAB-VPN-01 — Disable Public Endpoint

In `scripts/02-create-cluster` eksctl config:

```yaml
vpc:
  clusterEndpoints:
    privateAccess: true
    publicAccess: false
```

> Warning: Changing this on a running cluster requires the change to be applied via `aws eks update-cluster-config`. The cluster itself does not need to be recreated, but `kubectl` access will be lost until the VPN is active.

## LAB-VPN-02 — EC2 WireGuard Gateway

Provisioned in a new script `scripts/18-setup-vpn`:

- **AMI:** latest Amazon Linux 2023 (WireGuard available via `dnf`)
- **Instance type:** `t3.micro`
- **Subnet:** public subnet (`10.0.1.0/24`)
- **Security Group:** inbound UDP 51820 restricted to operator IPs (CIDR list in `env.conf`)
- **Elastic IP:** allocated and associated

## LAB-VPN-03 — WireGuard Configuration

Server (`/etc/wireguard/wg0.conf` on EC2):

```ini
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <operator-public-key>
AllowedIPs = 10.8.0.2/32
```

Client (operator laptop `wg0.conf`):

```ini
[Interface]
Address = 10.8.0.2/24
PrivateKey = <operator-private-key>
DNS = 169.254.169.253   # VPC DNS resolver

[Peer]
PublicKey = <server-public-key>
Endpoint = <EC2-EIP>:51820
AllowedIPs = 10.0.0.0/16   # VPC CIDR only — split tunnel
PersistentKeepalive = 25
```

Split tunnel (`AllowedIPs = 10.0.0.0/16`) keeps all other traffic on the operator's default route.

## LAB-VPN-04 — kubeconfig Update

After enabling private access, update `kubeconfig` to use the private DNS endpoint:

```bash
aws eks update-kubeconfig \
  --region "${AWS_REGION}" \
  --name "${CLUSTER_NAME}" \
  --alias "${CLUSTER_NAME}-private"
```

The private endpoint DNS resolves to a VPC-internal IP — only reachable with the WireGuard tunnel active.

## Destroy entry

Add to `scripts/destroy` (before EKS cluster deletion):

```bash
# VPN gateway
aws ec2 release-address --allocation-id "${VPN_EIP_ALLOC_ID}" || true
aws ec2 terminate-instances --instance-ids "${VPN_INSTANCE_ID}" || true
aws ec2 delete-security-group --group-id "${VPN_SG_ID}" || true
```
