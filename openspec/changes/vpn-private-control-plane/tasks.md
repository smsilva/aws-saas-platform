# Tasks: VPN — Private EKS Control Plane

## LAB-VPN-01 — Private Endpoint

- [ ] Add `clusterEndpoints: privateAccess: true, publicAccess: false` to eksctl config in `scripts/02-create-cluster`
- [ ] Document the migration path for existing clusters (via `aws eks update-cluster-config`)

## LAB-VPN-02 — EC2 WireGuard Gateway

- [ ] Create `scripts/18-setup-vpn`
- [ ] Provision EC2 `t3.micro` in public subnet with Security Group allowing UDP 51820 from operator IPs
- [ ] Allocate and associate an Elastic IP
- [ ] Store `VPN_INSTANCE_ID`, `VPN_EIP_ALLOC_ID`, `VPN_SG_ID` in `scripts/env.conf` (dynamic values section)
- [ ] Add destroy entries to `scripts/destroy` in correct reverse order

## LAB-VPN-03 — WireGuard Installation and Configuration

- [ ] Install WireGuard on EC2 via `dnf install wireguard-tools`
- [ ] Generate server keypair: `wg genkey | tee server.key | wg pubkey > server.pub`
- [ ] Generate per-operator keypair
- [ ] Write server `wg0.conf` with IP forwarding and NAT masquerade rules
- [ ] Enable and start `wg-quick@wg0` systemd service
- [ ] Write operator client config (`wg0.conf`) with split tunnel for `10.0.0.0/16`

## LAB-VPN-04 — Route and DNS

- [ ] Verify operator laptop routes `10.0.0.0/16` through the WireGuard interface
- [ ] Confirm VPC DNS resolver (`169.254.169.253`) resolves the private EKS endpoint hostname

## LAB-VPN-05 — kubeconfig Update

- [ ] Run `aws eks update-kubeconfig` pointing to the private DNS endpoint
- [ ] Test: `kubectl get nodes` fails with VPN off
- [ ] Test: `kubectl get nodes` succeeds with VPN on

## LAB-VPN-06 — Validation

- [ ] Disable public access on the cluster: `aws eks update-cluster-config --resources-vpc-config endpointPublicAccess=false`
- [ ] Confirm `kubectl get nodes` is blocked from outside the VPN
- [ ] Confirm platform services (`wasp.silvios.me`, `auth.wasp.silvios.me`) remain accessible from the internet
- [ ] Confirm ALB health checks still pass (they originate within the VPC)

## Final

- [ ] Update `docs/well-architected-production-roadmap.md` — mark LAB-VPN-01~06 complete
- [ ] Add `18-setup-vpn` to the script table in `CLAUDE.md`
- [ ] Commit with `feat(scripts/18-setup-vpn): add WireGuard VPN for private EKS control plane`
