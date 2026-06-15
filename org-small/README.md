# Organization Small - Terraform Infrastructure

This directory contains the infrastructure-as-code (IaC) configuration for **Organization Small**, managing 3 core workloads (Legacy Monolith on EC2, Auto-scaled REST/gRPC API on ASG, and Microservices on EKS) alongside associated data stores, security baselines, and monitoring.

## Directory Structure

*   `modules/`: Contains reusable, parameterized resource configurations.
    *   `networking/`: VPC, subnets, NAT, and SSM endpoint routing.
    *   `security/`: Security Groups, NACLs, custom KMS keys, and ACM SSL certificates.
    *   `iam/`: IAM Roles and Instance Profiles.
    *   `ec2-legacy/`: Legacy Monolith active + standby VM instances.
    *   `asg-api/`: Auto-scaled stateless REST/gRPC API tier with ALB.
    *   `eks/`: Private EKS cluster and node groups (On-Demand & Spot).
    *   `rds/`: Multi-AZ PostgreSQL instance.
    *   `redis/`: ElastiCache Redis cluster.
    *   `efs/`: Elastic shared filesystem.
    *   `s3/`: Secure object storage.
    *   `secrets/`: Database password container in Secrets Manager.
    *   `backup/`: Standardized compliance backup vault and rules.
    *   `monitoring/`: CloudWatch dashboards and alerts.
*   `environments/`: Configuration workspaces for separate environments.
    *   `dev/`: Cost-optimized single-zone deployment.
    *   `staging/`: Pre-production scale simulation workspace.
    *   `prod/`: Highly available, Multi-AZ production deployment.

## Requirements

*   Terraform `>= 1.5.0`
*   AWS Provider `>= 5.0`
*   Registered Route 53 Domain Zone

## Usage

1.  Navigate to the environment directory you wish to deploy:
    ```bash
    cd environments/dev
    ```
2.  Initialize Terraform:
    ```bash
    terraform init
    ```
3.  Perform formatting and syntax validation:
    ```bash
    terraform fmt -recursive
    terraform validate
    ```
4.  Generate and review the plan:
    ```bash
    terraform plan
    ```
5.  Apply the plan (requires AWS credentials):
    ```bash
    terraform apply
    ```

## Maintainers

*   **Platform Engineering Team** (devops@company-small.io)
