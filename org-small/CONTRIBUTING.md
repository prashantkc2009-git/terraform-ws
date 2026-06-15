# Contributing to Organization Small Infrastructure

We welcome contributions to improve the reliability, security, and scalability of our infrastructure.

## Development Workflow

1.  **Create a Branch**: Create a feature branch from `main` (e.g., `git checkout -b feature/rds-optimization`).
2.  **Make Code Changes**: Write clean, parameterized Terraform configurations under `modules/` and apply them to the target env in `environments/`.
3.  **Run Quality Checks**:
    *   Format your code: `terraform fmt -recursive`
    *   Validate configurations: `terraform validate` in the respective environment folder.
    *   Check for security issues locally using `tfsec` or `checkov`.
4.  **Submit a Pull Request**: Push your branch to GitHub and create a PR. Our CI/CD pipeline will automatically run validation and security checks.
5.  **Peer Review**: A minimum of one review from the Maintainers team is required.

## Style Guidelines

*   **Naming Standards**: Use snake_case for all resource names and variables.
*   **Variable Descriptions**: Every variable and output *must* include a descriptive explanation.
*   **Encryption**: All storage resources (EBS, EFS, RDS, S3) must enable default KMS encryption.
*   **Access Control**: Security groups and IAM permissions must follow the principle of least privilege.
