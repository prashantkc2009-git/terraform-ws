# Implementation Review

**Version:** 1  
**Status:** Resolved

## Critical Issues (will break or cause security incidents)

- **Hardcoded DB password in `org-mid/modules/secrets/main.tf`**: `password = "SuperSecurePassword123!"` is plaintext in source code. Needs `random_password` like `org-small` does.
- **GitHub Actions OIDC provider is a data source, not a resource**: If the OIDC provider doesn't already exist in the account, `terraform apply` fails. `org-small` correctly creates it with `aws_iam_openid_connect_provider`.
- **GitHub Actions policy has `Resource = "*"` on everything**: EC2, S3, RDS, EKS, IAM, KMS, SSM, all with wildcard resources. Effectively admin access.

## Structural Issues (won't work as intended)

- **No NAT Gateway defined**: Private, data, endpoint, and TGW subnets have zero outbound internet access. They share one route table with no NAT route.
- **WAF Web ACL has zero rules**: Just a default `allow {}` block. It's a complete passthrough, providing no protection.
- **EKS cluster roles are defined but there are no compute modules**: The IAM roles exist but nothing uses them. `org-mid` has no EC2, ASG, or EKS resources yet.

## Security Hardening Issues

- **App SG allows entire `10.0.0.0/8` inbound on all ports/protocols**: Should be scoped to specific ports.
- **Data SG allows ALL protocols from app SG (`protocol = "-1"`)**: Should restrict to specific ports (5432, 6379, etc.) like `org-small` does.
- **KMS deletion window = 7 days**: Production standard is 30 days.
- **S3 buckets have no bucket policies**: No access controls limiting which principals can access them.
- **No auto-rotation for Secrets Manager**: Design doc calls for it but it's not implemented.

## Missing Features

- **No `backend.tf`**: Terraform state is stored locally. Needs S3 + DynamoDB.
- **Only one environment (dev)**: No staging or prod directories or tfvars.
- **No cross-region replication**: `enable_replication` and `dr_region` variables are declared but unused.
- **No SSM VPC Endpoints**: Session Manager won't work from private subnets.

## Design Concern

- **Organizations module only creates org/OUs/SCPs in prod**: The dev environment runs without any organization structure. The root user SCP denies `Action = "*"` when principal matches `*:root`, which would break AWS support access.

