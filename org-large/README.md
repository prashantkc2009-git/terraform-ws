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
