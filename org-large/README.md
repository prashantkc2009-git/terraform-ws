# Organization Large - Terraform Infrastructure & Architecture Design

This directory contains the infrastructure-as-code (IaC) architectural designs, guidelines, and reference specifications for **Organization Large** (Enterprise level).

## Directory Structure

*   `company-large.md`: Comprehensive enterprise infrastructure specification covering global active-active designs, multi-account structures, AWS Control Tower/SCPs, Transit Gateway Cloud WAN networks, GitOps pipelines, global observability, disaster recovery, FinOps, and Architectural Decision Records (ADRs).
*   `modules/`: (Future) Reusable, highly parameterized Terraform modules designed for multi-account and multi-region deployment.
*   `environments/`: (Future) Multi-account orchestrations (Dev, QA, Staging, Production-US, Production-EU, Data Lake, Security, Shared Services, Network).

## Enterprise Objectives

1.  **Global Scale**: Active-Active multi-region architecture with sub-second data replication and global DNS routing.
2.  **High Compliance**: Designed to exceed standards for SOC 2 Type II, PCI DSS Level 1, HIPAA, and GDPR.
3.  **Strict Security Guardrails**: Enforcement of least privilege through AWS Organizations SCPs, Permission Boundaries, and AWS Network Firewalls.
4.  **Platform Engineering & GitOps**: Complete self-service infrastructure blueprints managed via GitOps (ArgoCD) and secure, signed CI/CD pipelines.

## Maintainers

*   **Enterprise Architecture & SRE Core Team** (platform-eng@company-large.io)




## New Module Structure (68 files, 26 modules)
modules/
├── common/
│   └── standard-tags/               ← P1.5: Mandatory tags for all resources
├── foundation/                       ← Platform Team Only
│   ├── aws-organization/            ← Org, OUs, SCPs, Developer IAM Boundary
│   ├── aws-cloud-wan/               ← Global network fabric & policies
│   ├── aws-network-firewall/        ← Inspection VPC & firewall rules
│   └── aws-control-tower/           ← Guardrails
├── shared/                           ← Platform + SRE (12 modules)
│   ├── vpc-base/                    ← VPC, subnets, SG tiering
│   ├── eks-cluster-blueprint/       ← EKS, node groups, IAM
│   ├── aurora-global-database/      ← Aurora Global with write-forwarding
│   ├── dynamodb-global-table/       ← DDB with global replicas
│   ├── msk-cluster/                 ← Kafka streaming
│   ├── kms-multi-region-key/        ← MRK management
│   ├── waf-canary/                  ← WAF Web ACL
│   ├── secrets-manager/             ← Secrets with rotation Lambda
│   ├── observability/               ← Thanos, Log Archive, Flow Logs
│   ├── github-oidc/                 ← OIDC provider + Plan/Apply roles
│   ├── terraform-state-backend/     ← S3 + DynamoDB + KMS per account
│   └── data-lifecycle/              ← Glacier transitions + AWS Backup
├── self-service/                     ← All 40+ Squads (5 modules)
│   ├── app-s3-bucket/               ← Compliant S3
│   ├── app-dynamodb-table/          ← DDB with KMS/PITR
│   ├── app-lambda-function/         ← Lambda with VPC + IAM boundary
│   ├── app-ecs-service/             ← Fargate with ALB
│   └── app-sqs-queue/               ← Queue with DLQ
└── specialized/                      ← Restricted (4 modules)
    ├── sagemaker-hyperpod/          ← ML training
    ├── hybrid-connectivity/         ← VPN + EC2 Bare Metal
    ├── fsx-lustre/                  ← High-throughput FS
    └── lake-formation/              ← Cell-level PII filtering
Environment Structure (52 files)
- global/foundation/ — Org, Cloud WAN, Control Tower (once, org-wide)
- {dev,stage,prod}/foundation/ — Network Firewall per account
- {dev,stage,prod}/shared/ — VPC, EKS, DBs, KMS, WAF, secrets, etc.
- {dev,stage,prod}/self-service/ — App modules with example
- {dev,stage,prod}/specialized/ — SageMaker, hybrid, FSx, Lake Formation
All required_version set to >= 1.9.0 per master plan. Old flat modules and single-file environments deleted.