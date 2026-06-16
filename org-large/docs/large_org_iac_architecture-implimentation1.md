# Enterprise IaC Implementation Plan: Multi-Repo GitOps for 300+ Applications

**Based On:** `large_org_iac_architecture.md` v2.0.0
**Status:** Draft Implementation Plan
**Target Organization:** 200–300 standard apps + 50 shared platform apps across 40+ squads

---

## Overview

This plan breaks the architecture into **6 sequential phases**, each with clear deliverables, dependencies, and success criteria. Phases build on each other — later phases assume earlier foundations are in place.

---

## Phase 0: Foundation & Governance (Weeks 1–4)

### Objective
Establish the organizational, security, and tooling foundations that every subsequent phase depends on.

### Deliverables

#### 0.1 — Platform Team Structure & RACI
- Define Platform Engineering team composition (minimum: IaC lead, Security engineer, SRE, 2–3 module engineers)
- Publish RACI matrix for each tier:
  - Tier 1 (Core): Platform only
  - Tier 2 (Shared Services): Platform + SRE
  - Tier 3 (App Workloads): Product teams self-service
- Establish InnerSource contribution governance model (PR template, review SLA of 24h, merge criteria)

#### 0.2 — Private Module Registry
- Deploy private Terraform module registry (Terraform Cloud / Enterprise or self-hosted)
- Configure Renovate to pull only from internal namespace
- Set up Cosign for upstream dependency hash verification
- Define semantic versioning policy (`~> x.y` for all golden modules)

#### 0.3 — OIDC & CI/CD Base Template
- Deploy GitHub OIDC provider in the root/management AWS account
- Create `GitHubActions-TerraformPlan` and `GitHubActions-TerraformApply` IAM roles (pinned per repo)
- Write the reusable `.github/workflows/terraform.yml` pipeline template (plan on PR, apply on main)
- Write the reusable `.github/workflows/infracost.yml` cost estimation template
- Write the reusable `.github/workflows/terraform-docs.yml` docs template
- Push templates to an org-level `.github` repository

#### 0.4 — Security Baseline Pipeline
- Enable AWS GuardDuty, Security Hub, Config, Inspector organization-wide
- Deploy Checkov/OPA scanning as a required PR gate in the CI template
- Configure Kyverno + Cosign verification for EKS clusters (prepped for Phase 4)
- Establish incident response automation (SSM Incident Manager playbooks)

### Dependencies
- None (this is the starting phase)

### Success Criteria
- [ ] Private module registry is operational and accepting modules
- [ ] CI/CD pipeline template is published and can be applied to any new repo
- [ ] OIDC trust policies are tested and verified for Plan vs. Apply separation
- [ ] Security scanning gates are enforced at PR level
- [ ] Platform team is staffed and RACI is approved

---

## Phase 1: Core Infrastructure (Weeks 3–8)

### Objective
Provision the foundational AWS infrastructure that all accounts and applications depend on.

### Deliverables

#### 1.1 — AWS Organization & Control Tower
- Configure AWS Organizations with proper OU structure (Root → Security, Platform/Core Network, Application Accounts)
- Deploy AWS Control Tower with guardrails and SCPs
- Enable CloudTrail Organization Trail with Log File Integrity Validation and immutable S3 bucket lock

#### 1.2 — State Backend Module
- Build `modules/security/terraform-state-backend/` (S3 bucket + DynamoDB table + KMS key)
- Deploy one state backend per AWS account manually for initial accounts
- Later accounts get this via AFT customizations (Phase 2)

#### 1.3 — Standard Tags Module
- Build `modules/common/standard-tags/` with mandatory tags: System, Environment, Team, CostCenter, ManagedBy, Module, CreatedAt
- All golden modules must consume this module for resource tagging

#### 1.4 — Network Foundation
- Deploy AWS Cloud WAN (global network fabric)
- Set up Transit Gateway with central Inspection VPC
- Deploy AWS Network Firewall in Inspection VPC
- Create base VPC CIDR allocations via IPAM

#### 1.5 — OIDC Provider & Core Roles
- Deploy `modules/security/github-oidc/` for GitHub Actions OIDC federation
- Create organization-level Plan/Apply roles with pinned subject conditions

#### 1.6 — KMS Multi-Region Keys
- Deploy `modules/security/kms-multi-region-key/` (MRK prefix)
- Establish alias conventions for cross-account access

### Dependencies
- Phase 0 complete (registry, pipeline templates, team)

### Success Criteria
- [ ] Organization + Control Tower operational with OUs, SCPs, guardrails
- [ ] State backends deployed for all initial accounts
- [ ] Network fabric (Cloud WAN, TGW, Inspection VPC) tested
- [ ] OIDC roles working with pinned subject conditions
- [ ] KMS MRKs deployed in `us-east-1` and `eu-west-1`

---

## Phase 2: Automation & Account Vending (Weeks 6–12)

### Objective
Automate account provisioning with baseline security, networking, and state backends — enabling self-service for new LOB accounts.

### Deliverables

#### 2.1 — AFT Account Factory
- Deploy AWS Control Tower Account Factory for Terraform (AFT)
- Build `account-customizations/pci-compliant-baseline/` with:
  - VPC module (CIDR from IPAM)
  - State backend module
  - Security baseline (GuardDuty, Security Hub, Inspector, Config)
  - IAM boundaries module (`DeveloperPolicyBoundary`)
- Build `account-customizations/standard-baseline/` for non-PCI accounts

#### 2.2 — Account Request Module
- Build the `aft-account-request` module with:
  - Control Tower parameters (email, name, OU, SSO user)
  - Account tags (Environment, LOB, CostCenter, Compliance)
  - Customization selection (baseline variant)
  - Change management metadata

#### 2.3 — ArgoCD Registration
- Deploy ArgoCD in Active-Standby model across `us-east-1` and `eu-west-1`
- Automate registration of new accounts in ArgoCD via AFT customizations

#### 2.4 — SSM Parameter Store Convention
- Establish SSM path conventions for cross-tier data sharing:
  - `/platform/network/vpc_id`
  - `/platform/network/private_subnet_ids`
  - `/platform/network/public_subnet_ids`
  - `/compliance/kms_mrk_arn`
  - `/platform/security/log_archive_bucket`
- Document discovery pattern: app modules read via `data.aws_ssm_parameter` (never direct state coupling)

### Dependencies
- Phase 1 complete (Control Tower, network, KMS, state backends)

### Success Criteria
- [ ] AFT can provision a new PCI-compliant account end-to-end with ~20 lines of HCL
- [ ] Baseline customizations include VPC, state backend, security, IAM boundaries
- [ ] ArgoCD registers new accounts automatically
- [ ] SSM convention documented and enforced via golden modules

---

## Phase 3: Golden Module Development (Weeks 8–20)

### Objective
Build the full golden module catalog across all workload families. This is the most resource-intensive phase.

### Deliverables — Priority Order

#### Priority P0 (Self-Service App Modules — All squads consume these)
| Module | Est. Effort | Key Features |
|--------|------------|--------------|
| `app-s3-bucket` | 1 sprint | Encryption, lifecycle, public access blocks, cross-region replication, object lock |
| `app-dynamodb-table` | 1 sprint | Global tables, TTL, PAY_PER_REQUEST, DAX, point-in-time recovery |
| `app-lambda-function` | 1 sprint | VPC config, IAM boundary, reserved concurrency, DLQ, snapstart |
| `app-ecs-service` | 2 sprints | Fargate, ALB/NLB, service discovery, auto-scaling, circuit breaker |
| `app-sqs-queue` | 0.5 sprint | DLQ, KMS encryption, redrive policy, fifo/standard |

#### Priority P1 (Shared Platform Modules — Platform + SRE controlled)
| Module | Est. Effort | Key Features |
|--------|------------|--------------|
| `eks-cluster-blueprint` | 3 sprints | Karpenter, Istio Ambient Mesh, OTel, Kyverno, cert-manager, ACM PCA |
| `aurora-global-database` | 2 sprints | Multi-region write-forwarding, auto-scaling, backtrack, IAM auth |
| `secrets-manager` | 1 sprint | Auto-rotation (Lambda), MR replication, cross-account access |
| `kms-multi-region-key` | 1 sprint | MRK aliases, key policies, automatic key rotation |

#### Priority P2 (Workload-Specific Modules — GAP-12/13/14)
| Module | Est. Effort | Key Features |
|--------|------------|--------------|
| `sagemaker-hyperpod` | 2 sprints | Training cluster, instance groups, KMS encryption, VPC |
| `fsx-lustre` | 1 sprint | PERSISTENT_2, S3 import/export, KMS, subnet placement |
| `data-lakehouse` | 2 sprints | Lake Formation cell-level security, S3 Iceberg, column masking |
| `hybrid-connectivity` | 2 sprints | DX (dual carrier), VPN failover, Cloud WAN integration |
| `bare-metal-host` | 1 sprint | Dedicated host, io2 EBS, hardened AMI, placement groups |

#### Priority P3 (Foundation Modules — Platform only)
| Module | Est. Effort | Key Features |
|--------|------------|--------------|
| `aws-organization` | 1 sprint | OU structure, SCPs, delegated admins |
| `aws-control-tower` | 1 sprint | Guardrails, Landing Zone, shared accounts |
| `aws-cloud-wan` | 1 sprint | Global network, routing policies, segment attachments |
| `aws-network-firewall` | 1 sprint | Suricata rules, inspection VPC, TLS inspection |
| `iam-boundaries` | 1 sprint | DeveloperPolicyBoundary, admin boundary |

#### Priority P4 (Operational Modules — GAP-15/16/17)
| Module | Est. Effort | Key Features |
|--------|------------|--------------|
| `drift-detection` | 1 sprint | Weekly plan runs, SNS alerts, Slack integration |
| `github-oidc` | 0.5 sprint | OIDC provider, Plan/Apply roles |
| `terraform-state-backend` | 0.5 sprint | S3 + DynamoDB + KMS per account |

### Quality Gates for Every Module
- [ ] `tflint` passes with zero warnings
- [ ] Checkov scan passes (soft_fail: false)
- [ ] `terraform-docs` auto-generated README with inputs/outputs/examples
- [ ] Integration tests pass (CDKTF/Terratest in isolated account)
- [ ] Semantic version `~> x.y` constraint applied
- [ ] Standard tags consumed from `modules/common/standard-tags/`
- [ ] All secrets marked `sensitive = true`
- [ ] SSM Parameter Store data sources used (no direct state coupling)

### Dependencies
- Phase 0 complete (registry, pipeline templates, team)
- Phase 1 complete (KMS MRKs, networking, tags module)

### Success Criteria
- [ ] All P0 modules published to private registry with passing validation pipelines
- [ ] P1 modules tested with integration tests
- [ ] P2 modules cover AI/ML, Lakehouse, and Hybrid workload families
- [ ] Module promotion pipeline (`dev → staging → prod`) is operational
- [ ] App team can provision compliant infrastructure in ~20 lines of HCL

---

## Phase 4: Application Repositories & Migration (Weeks 16–30)

### Objective
Onboard all 300+ application repositories onto the multi-repo GitOps pattern with golden module consumption.

### Deliverables

#### 4.1 — Application Repository Template
- Create a `terraform/` directory template with:
  - `main.tf` (thin HCL consuming P0 modules + README example)
  - `backend.tf` (parameterized via CI vars: bucket, key, region, dynamodb_table)
  - `providers.tf` (AWS provider with region alias for multi-region)
  - `variables.tf` (standard vars: app_name, environment, team, cost_center)
  - `.github/workflows/terraform.yml` (from org template)
  - `.github/workflows/infracost.yml` (from org template)

#### 4.2 — Onboarding Playbook
- Write a developer-facing onboarding guide:
  1. "[Create Repository] → Use template → Clone"
  2. "Edit `terraform/main.tf` — add your P0/P1 modules"
  3. "Set repo vars: AWS_ACCOUNT_ID, ENVIRONMENT"
  4. "Open PR → automated plan + Checkov + Infracost"
  5. "Merge to main → automated apply"
  6. "Verify resources in AWS console"
- Target: New repos provisioned in under 30 minutes of developer time

#### 4.3 — Progressive Adoption Program (GAP-18)
- Audit all existing 300+ repos for current maturity level:
  ```
  Level 0: Raw HCL (legacy)         → Compliance scanning only
  Level 1: Golden Module consumption → Team trained
  Level 2: Full GitOps pipeline      → Automated plan/apply
  Level 3: Portal-provisioned        → Zero-touch (future)
  Level 4: Policy-as-Code gated      → Automated certification (future)
  ```
- Tag each repo with maturity level in repo metadata
- Prioritize migration: Level 0 teams with highest compliance risk first
- Use Terraform `import` blocks (1.5+) for adopting existing resources:
  ```hcl
  import {
    to = module.app_s3_bucket.aws_s3_bucket.this
    id = "existing-legacy-bucket-name"
  }
  ```

#### 4.4 — Migration Support
- Dedicate 1 platform engineer per 20 migrating squads (hand-holding during transition)
- Weekly office hours and migration office hours
- Migration window scheduling with app team POCs

### Dependencies
- Phase 3 complete (P0 modules published, P1 modules ready)

### Success Criteria
- [ ] Repository template is published and test-driven by 3 pilot teams
- [ ] Onboarding playbook is peer-reviewed by an app team lead
- [ ] 10 pilot application teams migrated to Level 2 (GitOps pipeline)
- [ ] Migration path for importing existing resources is validated

---

## Phase 5: Continuous Operations & Enforcement (Weeks 24–40+)

### Objective
Automate drift detection, cost governance, policy enforcement, and dependency updates across all 300+ repos.

### Deliverables

#### 5.1 — Drift Detection (GAP-15)
- Deploy `modules/observability/drift-detection/` (Lambda + EventBridge + SNS)
- Schedule weekly `terraform plan` runs across all repos (Monday 6 AM UTC)
- Route alerts to team-specific Slack channels + centralized SNS topic
- Track drift metrics in a dashboard (repo, resources drifted, first seen, severity)

#### 5.2 — Cost Estimation Enforcement (GAP-16)
- Roll out Infracost to all repos via org pipeline template
- Block PR merges if cost increase exceeds 20% without approved comment
- Publish monthly FinOps showback reports per LOB budget code

#### 5.3 — Dependency Renovation (GAP-11)
- Deploy Renovate on all 300+ repos
- Auto-merge minor/patch module updates when integration tests pass
- Create major version updates as PRs for manual review
- Track "time-to-merge" metric for dependency updates

#### 5.4 — Policy-as-Code Enforcement
- Deploy OPA policies for:
  - Mandatory tagging (all resources must have `CostCenter`, `Environment`, `Team`)
  - Encryption requirements (S3, EBS, RDS must have KMS)
  - Public access blocks (S3 buckets must block public access)
  - Region restriction (resources only in `us-east-1`, `eu-west-1`)
- Block PR merges that violate any policy
- Publish compliance score per repo/squad on a centralized dashboard

#### 5.5 — Module Registry Governance
- Configure Renovate to only pull from private registry namespace
- Enforce `~> x.y` version constraints (no floating `latest`)
- Automated module deprecation notices with 90-day min warning
- Track module version adoption across all repos (identify laggards)

### Dependencies
- Phase 4 complete (repos onboarded and operational)

### Success Criteria
- [ ] Drift detection running weekly across all onboarded repos
- [ ] Infracost PR comments enforced as merge gate
- [ ] Renovate auto-merging minor/patch updates with passing tests
- [ ] OPA policies block non-compliant PRs before merge
- [ ] Compliance dashboard shows >90% adherence across all repos

---

## Phase 6: Developer Portal & Platform-as-a-Product (Weeks 40–60+)

### Objective
Build the Internal Developer Portal (Backstage) for zero-touch infrastructure provisioning — eliminating the need for app teams to write HCL altogether.

### Deliverables

#### 6.1 — Backstage Deployment
- Deploy Backstage (or equivalent internal developer portal)
- Integrate with GitHub, PagerDuty, AWS, and the private module registry
- Set up Software Catalog with all microservices

#### 6.2 — "Create Microservice" Scaffolder Template
- Backstage Software Template that:
  1. Prompts for app_name, team, cost_center, workload type (transactional, serverless, ML, analytics, legacy)
  2. Creates a new GitHub repository from template
  3. Provisions a dedicated AWS account via AFT (if new LOB)
  4. Writes `terraform/main.tf` with appropriate P0/P1/P2 modules
  5. Configures CI/CD (from org template)
  6. Registers the service in Backstage catalog
  7. Triggers initial `terraform apply`

#### 6.3 — Break-Glass Exception Flow
- For cases where golden modules don't cover a requirement:
  1. Developer submits architecture variance request via portal
  2. Routes to platform team for 24h review SLA
  3. If approved: special module version with restricted access
  4. If rejected: guidance to use InnerSource contribution model

#### 6.4 — Maturity Level 3–4 Rollout
- Migrate all app repos from Level 2 (GitOps) to Level 3 (Portal-provisioned)
- Deploy Policy-as-Code gating for Level 4 (automated compliance certification)
- Target: 90% of repos at Level 3+, 50% at Level 4

### Dependencies
- Phases 0–4 complete (modules, repos, automation)
- Phase 5 partially complete (drift detection, cost governance)

### Success Criteria
- [ ] Developer can provision compliant infrastructure without writing HCL
- [ ] Zero-touch account + repo + pipeline provisioning is demonstrated
- [ ] Architecture variance requests are resolved within SLA
- [ ] 90% of repos at Level 3 (portal-provisioned) or higher

---

## Summary: Critical Path & Resource Estimates

```
Weeks  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 ... 40 ... 60
0-Foundation    ████████████
1-Core Infra        ████████████████
2-Account Vending       ████████████████████
3-Golden Modules                    ████████████████████████████
4-App Migration                                    ████████████████████████
5-Continuous Ops                                                    ████████████...
6-Dev Portal                                                                  ████████████...
```

| Phase | Duration | Platform Team | Key Risk |
|-------|----------|---------------|----------|
| 0. Foundation | 4 weeks | 3–4 engineers | Underestimating OIDC + security setup complexity |
| 1. Core Infra | 6 weeks | 4–5 engineers | Control Tower deployment issues with existing accounts |
| 2. Account Vending | 6 weeks | 3–4 engineers | AFT customization debugging |
| 3. Golden Modules | 12 weeks (P0-P2), ongoing (P3-P4) | 5–8 engineers | Scope creep on module features |
| 4. App Migration | 14 weeks (pilot), 30 weeks (full) | 1 eng per 20 squads + all app teams | App team resistance to change |
| 5. Continuous Ops | Ongoing from week 24 | 2–3 engineers | Drift alert fatigue |
| 6. Dev Portal | 20 weeks+ | 4–6 engineers | Portal adoption lag |

### Key Risk Mitigations

| Risk | Mitigation |
|------|-----------|
| **Golden modules lag behind app team needs** | InnerSource contribution model + 24h review SLA. App teams submit PRs directly. |
| **App team resistance to migration** | Executive sponsorship, clear ROI communication, dedicated migration support per 20 squads. |
| **State migration data loss** | Automated `terraform state pull` backup before any `state mv`. Blue-green state validation: validate zero-change plan before decommissioning old state. |
| **Portal becomes a bottleneck** | Build circuit breakers — fallback to direct repo Git PRs for break-glass emergency updates. |
| **Module supply chain poisoning** | Private registry only. Cosign verification. Renovate restricted to internal namespace. |

---

## Verification Plan

### Pre-Production Validation
1. **Unit tests (Terratest)**: Every golden module has integration tests against isolated AWS account
2. **Security scan gates**: Checkov/OPA on every PR — zero soft-fail allowed
3. **Promotion pipeline**: Module changes flow `dev → staging → prod` with integration tests at each gate
4. **Pilot program**: 3 volunteer app teams validate the onboarding playbook before wider rollout

### Production Monitoring
1. **Weekly drift scans**: Automated `terraform plan` across all repos → SNS/Slack alerts
2. **Cost dashboards**: Infracost per-repo, Kubecost per-EKS-namespace
3. **Compliance dashboard**: OPA policy adherence % per squad, updated every PR
4. **Module adoption metrics**: Version spread, laggards, deprecation compliance

### Disaster Recovery Validation
1. **Quarterly DR drill**: Simulate regional failover, validate 5-minute RTO for ArgoCD standby
2. **Weekly chaos (FIS)**: Random pod/network/region failures under load
3. **Monthly restore test**: Automated Step Functions restore DB snapshots to isolated VPC, verify schemas
