# Terraform Workspace

Welcome to the Terraform practice workspace. This repository contains Infrastructure-as-Code (IaC) configurations for managing AWS workloads across two organization profiles.

## Organizations

### [org-mid](org-mid/) — Mid-Size Company
| Area | Details |
|---|---|
| **Focus** | Multi-account AWS Organizations with TGW, SCPs, and modular infrastructure for ~100-500 employee companies |
| **Environments** | `dev` (single), designed for `staging` and `prod` extension |
| **Modules** | [networking](org-mid/modules/networking), [security](org-mid/modules/security), [iam](org-mid/modules/iam), [organizations](org-mid/modules/organizations), [s3](org-mid/modules/s3), [secrets](org-mid/modules/secrets) |
| **Design** | [company-mid.md](org-mid/company-mid.md) — 576-line architecture document covering 5 workload families, multi-account strategy, DR, and cost projections |

**Getting started:**
```bash
cd org-mid/environments/dev
terraform init
terraform plan
```

### [org-small](org-small/) — Small Company
| Area | Details |
|---|---|
| **Focus** | Single-account 3-tier VPC with SSM-only access for ~10-50 employee companies |
| **Environments** | `dev`, `staging`, `prod` |
| **Modules** | 13 modules covering EC2, ASG, EKS, RDS, Redis, EFS, S3, backup, monitoring |
| **Design** | [company-small.md](org-small/company-small.md) — detailed architecture with 3 workload patterns |

**Getting started:**
```bash
cd org-small/environments/dev
terraform init
terraform plan
```

## Requirements

- Terraform `>= 1.5.0`
- AWS Provider `>= 5.0`

## Common Operations

```bash
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## Maintainers

- **Terraform Practice** (prashant@chandrakar.in)
