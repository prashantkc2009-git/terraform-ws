# Terraform Workspace

Welcome to the Terraform practice workspace. This repository contains the Infrastructure-as-Code (IaC) configuration for managing core AWS workloads for **Organization Small**.

## Directory Structure

The project is structured under the [org-small](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small) directory:

*   **[environments](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/environments)**: Environment-specific configurations:
    *   **[dev](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/environments/dev)**: Cost-optimized single-zone deployment.
    *   **[staging](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/environments/staging)**: Pre-production scale simulation environment.
    *   **[prod](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/environments/prod)**: Highly available, Multi-AZ production environment.
*   **[modules](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules)**: Reusable Terraform modules:
    *   [networking](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/networking): VPC, subnets, NAT, and routing.
    *   [security](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/security): Security Groups, NACLs, custom KMS keys, and ACM SSL certificates.
    *   [iam](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/iam): IAM Roles and Instance Profiles.
    *   [ec2-legacy](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/ec2-legacy): Active + standby VM instances.
    *   [asg-api](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/asg-api): Auto-scaled stateless tier with Application Load Balancer.
    *   [eks](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/eks): Private EKS cluster and node groups.
    *   [rds](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/rds): PostgreSQL database.
    *   [redis](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/redis): ElastiCache Redis cluster.
    *   [efs](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/efs): Shared filesystem.
    *   [s3](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/s3): Secure object storage.
    *   [secrets](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/secrets): AWS Secrets Manager configurations.
    *   [backup](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/backup): Backup vaults and rules.
    *   [monitoring](file:///Users/prashantkumar/MyDocument/workspace/openclaw-sandbox/workspace/terraform-ws/org-small/modules/monitoring): CloudWatch dashboards and alerts.

## Requirements

*   Terraform `>= 1.5.0`
*   AWS Provider `>= 5.0`

## Getting Started

1. Navigate to the desired environment directory (e.g., `dev`):
   ```bash
   cd org-small/environments/dev
   ```
2. Initialize the backend and provider plugins:
   ```bash
   terraform init
   ```
3. Format and validate the configuration:
   ```bash
   terraform fmt -recursive
   terraform validate
   ```
4. Preview changes:
   ```bash
   terraform plan
   ```
5. Apply the planned infrastructure changes:
   ```bash
   terraform apply
   ```

## Maintainers

*   **Terraform Practice** (prashant@chandrakar.in)