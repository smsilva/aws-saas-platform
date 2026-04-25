# Operations

This section covers the full lab lifecycle: initial provisioning (scripts 01–17), adding new tenants, and environment teardown.

## Available scripts

All scripts are in `scripts/`. Global configuration is in `scripts/env.conf`.

| Script | What it does |
|---|---|
| `01-create-vpc` | VPC, public/private subnets, IGW, NAT Gateway, route tables |
| `02-create-cluster` | EKS cluster + node group via eksctl |
| `03-configure-access` | EKS Access API + `AmazonEKSClusterAdminPolicy` for the caller IAM |
| `04-install-alb-controller` | Helm + IRSA for the AWS Load Balancer Controller |
| `05-install-istio` | Helm: `istio/base` + `istiod` + `istio/gateway` |
| `06-import-certificate-acm` | Imports the wildcard Let's Encrypt certificate into ACM |
| `07-configure-alb-ingress` | `Ingress` + `IngressClass` resource → provisions the ALB |
| `08-deploy-sample-app` | `httpbin` in the `sample` namespace to validate the traffic flow |
| `09-configure-waf` | WAF WebACL with managed rules + association to the ALB |
| `10-create-dynamodb` | DynamoDB `tenant-registry` table + example item (customer1) |
| `11-create-cognito` | User Pool, Google IdP, App Client, Pre-Token Generation Lambda |
| `12-configure-dns-cognito` | Cognito custom domain (`idp.wasp.silvios.me`) + CNAME in Azure DNS |
| `13-deploy-services` | Docker Hub build/push, discovery IRSA, deploy of 4 K8s namespaces |
| `14-configure-istio-auth` | `RequestAuthentication` + `AuthorizationPolicy` in the `customer1` namespace |
| `15-configure-waf-ratelimit` | WAF rate limiting for `/login` and `/callback` |
| `configure-idps` | Registers IdP (Google or Microsoft) + App Client + DynamoDB for a tenant |
| `17-deploy-customer2` | Deploy of the `customer2` namespace with Microsoft authentication |
| `destroy` | Removes all resources in reverse order |
| `destroy-auth` | Removes only the authentication stack (Cognito, DynamoDB, services) |

!!! warning "Pending script"
    `07b-configure-global-accelerator` — must be run between scripts 07 and 08. Provisions two static anycast IPs (Global Accelerator → ALB) for the `wasp.silvios.me` apex, whose ALB IPs are rotational and do not support static A records.

## Operational gotchas

!!! warning "`tenants.json` must have real Cognito values"
    `services/discovery/app/data/tenants.json` is a static data source. After reprovisioning Cognito, update `client_id` and `idp_pool_id` before the build, commit, and rebuild with a new SHA tag.

!!! warning "`COGNITO_DOMAIN` without `https://`"
    In the `platform-frontend-config` ConfigMap, the `COGNITO_DOMAIN` field must be just the hostname (`idp.wasp.silvios.me`). The code in `auth.py` already adds the scheme — putting the full URL generates `https://https://idp...`.

!!! warning "DynamoDB — reserved words in `--update-expression`"
    Attributes with reserved names (e.g. `auth`, `name`, `status`) cause `ValidationException`. Use `--expression-attribute-names` with a `#` alias:
    ```bash
    --update-expression 'SET #auth.field = :val' \
    --expression-attribute-names '{"#auth": "auth"}'
    ```

!!! warning "WAFv2 — `--id` requires UUID, not name"
    ```bash
    # CORRECT — $NF extracts the UUID (last segment of the ARN)
    web_acl_id="$(echo "${web_acl_arn}" | awk -F'/' '{print $NF}')"
    ```

## Pages in this section

- [Step-by-Step](passo-a-passo.md) — detailed execution of scripts 01–17
- [Customer Onboarding](../onboarding-novo-customer.md) — how to add a new tenant
- [Destroy the Lab](destruir-lab.md) — full and partial teardown
