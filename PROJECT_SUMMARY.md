# Project Summary & Change Log

## Repository Overview

Terraform practice workspace with two organization profiles:
- **org-mid**: Mid-size company (~100-500 employees) — multi-account AWS Organizations with TGW, SCPs, 6 modules
- **org-small**: Small company (~10-50 employees) — single-account 3-tier VPC, 13 modules

## org-mid Change Log

### 2026-06-15 — Security & Correctness Fixes

#### Critical Fixes

| # | Module | Issue | Fix |
|---|---|---|---|
| 1 | **secrets** | Hardcoded DB password `"SuperSecurePassword123!"` in source code | Replaced `random_password` resource (24-char, special chars). Added `hashicorp/random` provider. |
| 2 | **iam** | GitHub OIDC provider used `data` source (fails if provider doesn't exist) | Changed to `aws_iam_openid_connect_provider` resource with proper thumbprints |
| 3 | **iam** | GitHub Actions policy granted `Resource = "*"` for all actions (EC2, S3, RDS, EKS, IAM, KMS, SSM) | Scoped to least-privilege: specific ECR push, S3 deploy paths, EKS describe, SSM parameter read, KMS decrypt-with-condition, and scoped PassRole |

#### Networking Fixes

| # | Module | Issue | Fix |
|---|---|---|---|
| 4 | **networking** | No NAT Gateway — private/data/endpoint/tgw subnets had zero outbound internet access | Added conditional `aws_eip.nat` + `aws_nat_gateway.main` (active when `tgw_id == ""`). Added `dynamic` route block in private route table. |
| 5 | **networking** | `single_nat_gateway` variable not used | Removed — NAT GW condition is based on `tgw_id` presence, aligning with ADR-02 (central egress via TGW in multi-account, local NAT in standalone) |

#### Security Hardening

| # | Module | Issue | Fix |
|---|---|---|---|
| 6 | **security** | KMS `deletion_window_in_days = 7` (too short for production) | Changed to `30` |
| 7 | **security** | App SG allowed full `10.0.0.0/8` on all protocols | Scoped to specific app ports (8080, 50051) from edge SG, and TCP only from `var.vpc_cidr`. Added `vpc_cidr` variable. |
| 8 | **security** | Data SG allowed all protocols (`protocol = "-1"`) from app SG | Restricted to specific ports: 5432 (PostgreSQL), 6379 (Redis), 2049 (EFS), 9092/9098 (MSK Kafka) |
| 9 | **security** | WAF Web ACL had zero rules (passthrough only) | Added three AWS managed rule groups: CommonRuleSet, SQLiRuleSet, KnownBadInputsRuleSet |
| 10 | **s3** | No bucket policies on any buckets | Added `aws_s3_bucket_policy` enforcing HTTPS-only access across all 4 buckets |

#### IAM Improvements

| # | Module | Issue | Fix |
|---|---|---|---|
| 11 | **iam** | OIDC provider not in outputs | Added `github_oidc_provider_arn` output |
| 12 | **iam** | No `aws_region` variable for policy ARN construction | Added `aws_region` variable with default `us-east-1` |
| 13 | **iam** | Missing region in IAM policy ARNs | All policy resources now use `${var.aws_region}` for accurate ARN construction |

#### Environment Config Updates

| # | Module | Issue | Fix |
|---|---|---|---|
| 14 | **dev/main.tf** | Missing `tgw_id` in networking module call | Added `tgw_id = ""` with comment explaining NAT GW fallback |
| 15 | **dev/main.tf** | Missing `vpc_cidr` in security module call | Added `vpc_cidr = var.vpc_cidr` |
| 16 | **dev/main.tf** | Missing `aws_region` in IAM module call | Added `aws_region = var.aws_region` |
| 17 | **dev/main.tf** | Missing `random` provider declaration | Added `hashicorp/random ~> 3.6` |

#### Documentation

| # | File | Change |
|---|---|---|
| 18 | **README.md** | Rewrote to cover both org-mid and org-small with directory structure and quick-start for each |

### Open Issues (Not Addressed)

| Issue | Reason |
|---|---|
| No `backend.tf` (local state only) | Requires S3 + DynamoDB setup — should be configured per environment when remote state is provisioned |
| Only `dev` environment exists for org-mid | Staging and prod require multi-account setup with TGW and Organization resources |
| No compute modules (EC2, ASG, EKS) for org-mid | IAM roles exist but no compute resources — design doc defines 5 workload families to be implemented |
| No SSM VPC Endpoints | Private subnet SSM access requires interface endpoints (SSM, SSMMessages, EC2Messages) |
| Cross-region replication variables unused in S3 module | Variables declared but no replication configuration — requires DR region setup |
