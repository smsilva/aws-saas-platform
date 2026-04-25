# Destroy the Lab

## Full teardown

```bash
./scripts/destroy
```

Removes all resources in reverse order of the provisioning scripts. The script waits for each step to complete before proceeding to the next.

!!! danger "ACM is not removed automatically"
    The ACM certificate is not removed by the `destroy` script. Remove it manually:
    ```bash
    aws acm delete-certificate \
      --certificate-arn arn:aws:acm:us-east-1:221047292361:certificate/59ab7614-fa1b-4dba-9f43-7c775cfa5bac \
      --region us-east-1
    ```

## Partial teardown — authentication only

To remove only the authentication stack (Cognito, DynamoDB, K8s services) without bringing down the cluster:

```bash
./scripts/destroy-auth
```

Useful when you want to reprovision scripts 10–17 without recreating the base infrastructure (VPC, EKS, ALB, Istio).

## Removal order (full destroy)

| Step | What it removes |
|---|---|
| 17 → 10 | Tenant namespaces, Istio auth policies, WAF rate limiting |
| 9 | WAF WebACL (disassociates from ALB before deleting) |
| 8 | `sample` namespace and httpbin app |
| 7b | Azure DNS: wildcard CNAME `*.domain` and apex A records |
| 7b | Global Accelerator: endpoint group, listener, accelerator |
| 7 | `Ingress` resource (ALB is deleted by the controller) |
| 6 | ACM certificate **not removed** — see warning above |
| 5 | Istio (istiod, istio-base, istio-ingressgateway) |
| 4 | ALB Controller and IRSA role |
| 3 | EKS access entry |
| 2 | EKS cluster and node group |
| 1 | VPC, subnets, IGW, NAT Gateway, EIP, route tables |

!!! warning "NAT Gateway + EIP"
    The NAT Gateway and EIP incur hourly costs even when the cluster is not in use. If pausing the lab without destroying it, consider removing only these resources to reduce costs.
