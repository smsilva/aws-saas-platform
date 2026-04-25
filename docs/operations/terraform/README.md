# Terraform

The `terraform/` directory is the IaC layer for the lab. It complements the Bash provisioning scripts (`scripts/01–17`) and manages the same AWS resources — VPC, EKS, DynamoDB, Cognito, and WAF — with state tracking, drift detection, and a plan/apply workflow.

## Directory layout

```
terraform/
├── src/                        # Reusable modules
│   ├── vpc/
│   ├── eks/
│   ├── dynamodb/
│   ├── cognito/
│   │   └── userpool/           # Per-tenant submodule
│   └── waf/
└── examples/
    ├── common/                 # Shared provider + variable definitions
    └── lab/                    # Concrete lab deployment
```

`src/` contains standalone modules with no hard-coded values. `examples/lab/` is the concrete deployment that wires those modules together for this specific lab.

## Prerequisites

| Requirement | Version |
|---|---|
| Terraform | `>= 1.14.0, < 2.0.0` |
| AWS provider | `>= 6.0.0, < 7.0.0` |
| archive provider | `>= 2.0.0, < 3.0.0` |

**S3 backend** — state is stored remotely. Create a `backend.conf` in `examples/lab/` before running `make init`:

```ini
bucket = "<your-state-bucket>"
key    = "lab/terraform.tfstate"
region = "us-east-1"
```

**Google OAuth credentials** — required for the Cognito IdP. Pass them as variables or via environment:

```bash
export TF_VAR_google_client_id="..."
export TF_VAR_google_client_secret="..."
```
