# Implementation Plan: Enterprise IaC Architecture for 300+ Applications

**Document Metadata:**
- **Version:** 1.0.0
- **Status:** Draft
- **Last Updated:** 2026-06-16
- **Based On:** `large_org_iac_architecture.md` v2.0.0

---

## Table of Contents

1. [Plan Overview & Objectives](#1-plan-overview--objectives)
2. [Phase 0: Foundations (Weeks 1–4)](#2-phase-0-foundations-weeks-1-4)
3. [Phase 1: Golden Modules & Registry (Weeks 5–10)](#3-phase-1-golden-modules--registry-weeks-5-10)
4. [Phase 2: CI/CD Pipelines & OIDC (Weeks 8–14)](#4-phase-2-cicd-pipelines--oidc-weeks-8-14)
5. [Phase 3: Account Vending & State Backend (Weeks 10–16)](#5-phase-3-account-vending--state-backend-weeks-10-16)
6. [Phase 4: Security & Compliance Automation (Weeks 12–18)](#6-phase-4-security--compliance-automation-weeks-12-18)
7. [Phase 5: Application Migration Wave 1 (Weeks 14–22)](#7-phase-5-application-migration-wave-1-weeks-14-22)
8. [Phase 6: Advanced Workload Families (Weeks 16–26)](#8-phase-6-advanced-workload-families-weeks-16-26)
9. [Phase 7: Platform Operations & Drift Detection (Weeks 20–28)](#9-phase-7-platform-operations--drift-detection-weeks-20-28)
10. [Phase 8: Developer Portal & Self-Service (Weeks 22–36)](#10-phase-8-developer-portal--self-service-weeks-22-36)
11. [Phase 9: App Migration Waves 2–N (Weeks 20–52)](#11-phase-9-app-migration-waves-2--n-weeks-20-52)
12. [Phase 10: Continuous Improvement & InnerSource (Ongoing)](#12-phase-10-continuous-improvement--innersource-ongoing)
13. [Dependency Graph](#13-dependency-graph)
14. [Resource Estimation](#14-resource-estimation)
15. [Rollback Strategy](#15-rollback-strategy)
16. [Success Criteria & KPIs](#16-success-criteria--kpis)
17. [Risk Register](#17-risk-register)

---

## 1. Plan Overview & Objectives

### Goal
Implement a **Multi-Account, Multi-State, Multi-Repository** IaC architecture supporting 200–300 standard applications and 50 shared platform applications across 40+ product squads.

### Key Deliverables
| # | Deliverable | Phase |
| :--- | :--- | :--- |
| D1 | Standardized S3 + DynamoDB state backend per account | 0 |
| D2 | Golden Module Registry with foundation, shared, and self-service modules | 1 |
| D3 | CI/CD pipeline template with OIDC authentication for all repos | 2 |
| D4 | AWS Account Factory for Terraform (AFT) with baseline customizations | 3 |
| D5 | Policy-as-Code scanning (Checkov/OPA) enforced at PR gate | 4 |
| D6 | Wave 1 trial migration (5–10 app teams) | 5 |
| D7 | Workload-specific modules for AI/ML, Data Lakehouse, Hybrid/Legacy | 6 |
| D8 | Automated drift detection and operational tooling | 7 |
| D9 | Developer Portal (Backstage) with self-service app provisioning | 8 |
| D10 | Full migration of 300+ applications to golden module pattern | 9 |

### Guiding Principles
1. **Multi-Repo GitOps from Day One** for all new applications
2. **Existing apps migrate during scheduled windows** — no big-bang cutover
3. **Security scanning runs continuously** at the org level via centralized pipelines
4. **Platform team builds gates; app teams drive self-service**
5. **Every change is validated** — no direct `terraform apply` on production

---

## 2. Phase 0: Foundations (Weeks 1–4)

### Objective
Establish core infrastructure, team structure, and tooling prerequisites.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P0.1 | Set up AWS Organization with OU structure (Security, Platform, Application) | Platform Eng | 1 week | AWS root account access | OUs created; SCPs attached to base OUs |
| P0.2 | Deploy AWS Control Tower with central logging and audit accounts | Platform Eng | 1 week | P0.1 | Control Tower enrolled; all accounts governed |
| P0.3 | Configure IAM Identity Center (SSO) with permission sets | Platform Eng | 0.5 week | P0.1 | SSO groups mapped to OUs; users provisioned |
| P0.4 | Create centralized CI/CD runner account with GitHub Actions OIDC provider | Platform Eng | 0.5 week | P0.1 | OIDC provider deployed; trust policy tested |
| P0.5 | Establish private Terraform/OpenTofu module registry | Platform Eng | 1 week | P0.1 | Registry accessible; first test module published |
| P0.6 | Set up tagged Git repository structure for golden modules | Platform Eng | 0.5 week | — | Repos created with branch protection rules |
| P0.7 | Define standard tagging taxonomy (System, Environment, Team, CostCenter) | Platform + FinOps | 0.5 week | — | Tag schema published; modules enforce required tags |
| P0.8 | Deploy weekly compliance scanning pipeline (Checkov/OPA) at org level | Security Eng | 1 week | P0.4 | Scans run across all known IaC repos; dashboard online |
| P0.9 | Create developer sandbox accounts (non-prod) for local testing | Platform Eng | 1 week | P0.2 | Sandbox accounts ready; IAM boundaries applied |

### Gate: Phase 0 Complete
- [ ] AWS Organization with OUs active
- [ ] Control Tower enrolled and reporting
- [ ] SSO groups configured
- [ ] OIDC provider deployed
- [ ] Private module registry reachable
- [ ] Tag taxonomy published
- [ ] Compliance scanning operational
- [ ] Sandbox accounts available

---

## 3. Phase 1: Golden Modules & Registry (Weeks 5–10)

### Objective
Build the module catalog that all application teams will consume.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P1.1 | Build foundation modules: `aws-organization`, `aws-cloud-wan`, `aws-control-tower`, `aws-network-firewall` | Platform Eng | 2 weeks | P0.5 | All foundation modules published, versioned, tested |
| P1.2 | Build shared platform modules: `eks-cluster-blueprint`, `aurora-global-database`, `secrets-manager`, `kms-multi-region-key` | Platform Eng | 2.5 weeks | P1.1 | Modules published; SSM parameter output contracts defined |
| P1.3 | Build self-service app modules: `app-s3-bucket`, `app-dynamodb-table`, `app-lambda-function`, `app-ecs-service`, `app-sqs-queue` | Platform Eng | 2 weeks | P1.1 | Modules published with README examples; versioned |
| P1.4 | Build specialized modules: `sagemaker-hyperpod`, `databricks-workspace`, `fsx-lustre`, `hybrid-connectivity`, `bare-metal-host` | Platform Eng | 2.5 weeks | P1.1 | Published under restricted access scope |
| P1.5 | Implement semver release pipeline for all modules (dev → staging → prod promotion) | Platform Eng | 1 week | P1.2, P1.3, P1.4 | Pipeline promotes modules through environments; breaking changes gated |
| P1.6 | Create standard tags module (`modules/common/standard-tags`) | Platform Eng | 0.5 week | P0.7 | Tags output consumed by all golden modules |
| P1.7 | Build `terraform-state-backend` module with S3 + DynamoDB + KMS | Platform Eng | 1 week | P1.1 | Module deployable per account; versioned |
| P1.8 | Build `github-oidc` module for standardized OIDC role creation | Platform Eng | 1 week | P1.1 | Module creates Plan + Apply roles with pinned subject conditions |
| P1.9 | Build `security-baseline` module (GuardDuty, Security Hub, Inspector, Config) | Security Eng | 1 week | P1.1 | Module deployable per account; tested |
| P1.10 | Build `iam-boundaries` module with developer policy boundary | Security Eng | 0.5 week | P1.1 | Boundary policy tested; prevents privilege escalation |
| P1.11 | Add `terraform-docs` auto-generation CI workflow to all module repos | Platform Eng | 0.5 week | P0.6 | Module PRs auto-generate/update README |
| P1.12 | Add Renovate config to all module repos for dependency updates | Platform Eng | 0.5 week | P0.6 | Renovate opens PRs for minor/patch updates automatically |

### Gate: Phase 1 Complete
- [ ] Foundation modules published and tested
- [ ] Shared platform modules published with output contracts
- [ ] Self-service app modules published with examples
- [ ] Specialized modules published (restricted)
- [ ] Semver promotion pipeline operational
- [ ] Standard tags module consumed by all modules
- [ ] State backend module deployable per account
- [ ] OIDC module creates scoped roles
- [ ] Security baseline module tested
- [ ] IAM boundaries enforced
- [ ] terraform-docs CI on all module repos
- [ ] Renovate active on all module repos

---

## 4. Phase 2: CI/CD Pipelines & OIDC (Weeks 8–14)

### Objective
Standardize deployment pipelines across 300+ repos with secure OIDC authentication.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P2.1 | Create organization-level CI/CD workflow template (GitHub Actions) | Platform Eng | 1 week | P0.4 | Template available; includes plan, apply, Checkov, Infracost steps |
| P2.2 | Deploy OIDC roles (Plan + Apply) for 5 trial application accounts | Platform Eng | 1 week | P1.8 | Roles created; access test passes for each repo |
| P2.3 | Implement `checkov-action` security scanning in CI pipeline | Security Eng | 0.5 week | P2.1 | Pipeline blocks PRs with critical/high violations |
| P2.4 | Implement `infracost` cost estimation in CI pipeline | FinOps Eng | 0.5 week | P2.1 | PRs show cost diff; Infracost API key managed securely |
| P2.5 | Configure branch protection rules (main branch locked; PR required) | Platform Eng | 0.5 week | P0.6 | Rules enforced at org level; bypass restricted |
| P2.6 | Create standardized `backend.tf` template (auto-generated per repo) | Platform Eng | 0.5 week | P1.7 | Template references per-account bucket, per-app state key |
| P2.7 | Create repository template with reference `main.tf` (~20 lines consuming golden modules) | Platform Eng | 0.5 week | P1.2, P1.3, P2.6 | Template generates compliant repo skeleton |
| P2.8 | Build drift detection Lambda + CloudWatch schedule (weekly `terraform plan`) | Platform Eng | 1.5 weeks | P1.7, P2.1 | Lambda enumerates repos; drift results posted to SNS/Slack |
| P2.9 | Create developer sandbox wrapper (containerized local test environment) | Platform Eng | 1 week | P0.9 | Devs can run `terraform plan` locally against sandbox accounts |

### Gate: Phase 2 Complete
- [ ] CI/CD template available at org level
- [ ] OIDC roles deployed for trial accounts
- [ ] Checkov scans blocking PRs
- [ ] Infracost running on PRs
- [ ] Branch protection enforced
- [ ] backend.tf template ready
- [ ] Repository template ready
- [ ] Drift detection Lambda tested
- [ ] Developer sandbox available

---

## 5. Phase 3: Account Vending & State Backend (Weeks 10–16)

### Objective
Automate the provisioning of new AWS accounts with standardized baselines.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P3.1 | Deploy AWS Control Tower Account Factory for Terraform (AFT) | Platform Eng | 2 weeks | P0.2 | AFT management account configured; pipeline operational |
| P3.2 | Create AFT customization repository with baseline Terraform | Platform Eng | 1.5 weeks | P1.7, P1.9, P1.10, P3.1 | New accounts auto-provision VPC, state backend, security baseline, IAM boundaries |
| P3.3 | Define account request template (parameters, tags, customizations reference) | Platform Eng | 0.5 week | P3.2 | Request `main.tf` pattern documented and tested |
| P3.4 | Test full account vending pipeline (request → provision → customize → register) | Platform Eng | 1 week | P3.3 | End-to-end test passes; new account operational in < 2 hours |
| P3.5 | Deploy S3 + DynamoDB state backend to all existing accounts (via AFT retroactive customization) | Platform Eng | 1 week | P1.7, P3.2 | All accounts have state backend; locking enabled |
| P3.6 | Implement IPAM for VPC CIDR allocation across accounts | Platform Eng | 1 week | P3.2 | IPAM delegated admin; CIDR non-overlap enforced |
| P3.7 | Document account offboarding procedure (state backup, resource teardown, billing stop) | Platform Eng | 0.5 week | P3.4 | Procedure reviewed with Security and FinOps |

### Gate: Phase 3 Complete
- [ ] AFT deployed and operational
- [ ] Baseline customizations automated per account
- [ ] Account request template tested
- [ ] Full vending pipeline validated (E2E)
- [ ] State backend deployed to all accounts
- [ ] IPAM managing CIDR allocation
- [ ] Offboarding procedure documented

---

## 6. Phase 4: Security & Compliance Automation (Weeks 12–18)

### Objective
Embed security guardrails across all layers — from code to runtime.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P4.1 | Deploy Kyverno admission controller in all EKS clusters | Security Eng | 1 week | P1.2 | Pods without compliance labels / unsigned images blocked |
| P4.2 | Configure Cosign image signing in CI pipelines | Security Eng | 1 week | P2.1 | All container images signed; unsigned blocked by Kyverno |
| P4.3 | Implement Trivy vulnerability scanning in CI with SBOM generation | Security Eng | 1 week | P2.1 | CycloneDX SBOMs archived; critical vulns block deployment |
| P4.4 | Enable GuardDuty organization-wide with EKS audit log monitoring | Security Eng | 0.5 week | P0.2 | All accounts monitored; findings centralized in Security Hub |
| P4.5 | Deploy Falco/Tetragon runtime security in EKS clusters | Security Eng | 1 week | P1.2 | Anomalous process detection alerts routed to Security Hub |
| P4.6 | Configure IAM Access Analyzer at organization root | Security Eng | 0.5 week | P0.1 | Continuous monitoring active; findings reported |
| P4.7 | Set up CloudTrail Organization trail with log file validation + S3 bucket lock | Security Eng | 0.5 week | P0.2 | Immutable audit log archive; validation enabled |
| P4.8 | Implement automated restore testing (Step Functions for monthly DB restore drills) | Security Eng | 1.5 weeks | P1.2 | Restore test spins up ephemeral instance; validates data; tears down |
| P4.9 | Configure SSM Incident Manager with automated containment playbooks | Security Eng | 1 week | P0.2 | Playbooks isolate pods, revoke creds, snapshot volumes, page on-call |
| P4.10 | Establish WAF staging pipeline for progressive rule rollout | Security Eng | 1 week | P1.1 | WAF rules tested in staging before production deployment |
| P4.11 | Set up secrets replication (Secrets Manager multi-region) | Security Eng | 1 week | P1.2 | Secrets auto-replicate between `us-east-1` and `eu-west-1` |
| P4.12 | Deploy KMS Multi-Region Keys (MRK) with alias conventions | Security Eng | 0.5 week | P1.2 | MRKs created; app modules reference MRK ARN via SSM |

### Gate: Phase 4 Complete
- [ ] Kyverno blocking unsigned images
- [ ] Cosign signing mandatory in CI
- [ ] Trivy scanning + SBOM generation active
- [ ] GuardDuty organization-wide enabled
- [ ] Runtime security (Falco/Tetragon) deployed
- [ ] IAM Access Analyzer monitoring
- [ ] CloudTrail immutable audit trail active
- [ ] Automated restore testing operational
- [ ] Incident containment playbooks ready
- [ ] WAF staging pipeline active
- [ ] Secrets replicating across regions
- [ ] KMS MRKs deployed and referenced

---

## 7. Phase 5: Application Migration Wave 1 (Weeks 14–22)

### Objective
Pilot the migration with 5–10 early-adopter application teams, validate the full workflow, and refine based on feedback.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P5.1 | Recruit 5–10 pilot app teams; provide golden module training | Platform Eng | 1 week | P1.3 | Teams trained; sandbox accounts provisioned |
| P5.2 | Assess each pilot app's existing IaC; classify current maturity level (L0–L4) | Platform Eng + App Team | 1.5 weeks | P5.1 | Maturity baseline documented per app |
| P5.3 | Create per-app migration plan: identify resources to import, refactor, or replace | Platform Eng + App Team | 1 week | P5.2 | Migration plan reviewed and approved |
| P5.4 | Build Terraform import blocks for each app's existing unmanaged resources | App Team | 2 weeks | P1.3, P5.3 | Imports validated: `terraform plan` shows zero changes |
| P5.5 | Set up dedicated repo + CI/CD pipeline + OIDC roles for each pilot app | Platform Eng | 1 week | P2.1, P2.2, P5.4 | Pipelines green; plan/apply working |
| P5.6 | Execute state migration from legacy state to new per-app state backend | Platform Eng | 1 week | P5.5 | `terraform state pull` backup taken; `terraform plan` shows zero diff |
| P5.7 | Run shadow deployment: new pipeline parallel to old, compare plan outputs | Platform Eng + App Team | 1 week | P5.6 | No unexpected diff between old and new for 7 days |
| P5.8 | Cut over: switch DNS/CI triggers to new pipeline; decommission old state | Platform Eng + App Team | 0.5 week | P5.7 | Old pipeline disabled; rollback plan documented |
| P5.9 | Conduct retrospective with pilot teams; capture friction points and improvements | Platform Eng + All Pilot Teams | 0.5 week | P5.8 | Retro document published; Phase 5 process updated |

### Gate: Phase 5 Complete
- [ ] 5–10 pilot apps migrated to golden module pattern
- [ ] Zero-diff state migration validated
- [ ] New pipelines operational for pilot apps
- [ ] Retro findings documented
- [ ] Migration playbook refined for subsequent waves

---

## 8. Phase 6: Advanced Workload Families (Weeks 16–26)

### Objective
Build and validate modules for non-standard workloads: AI/ML, Data Lakehouse, Hybrid/Legacy.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P6.1 | Build SageMaker HyperPod training cluster module | Platform Eng | 1.5 weeks | P1.4 | Module supports configurable instance groups; tested with GPU instances |
| P6.2 | Build GPU Karpenter NodePool module for EKS ML workloads | Platform Eng | 1 week | P1.2, P1.4 | NodePool deployed via ArgoCD; GPU taints/ tolerations correct |
| P6.3 | Build FSx for Lustre data pipeline module | Platform Eng | 1 week | P1.4 | Module creates FSx with S3 import/export paths; KMS encrypted |
| P6.4 | Build Lake Formation with cell-level security module | Platform Eng | 1.5 weeks | P1.4 | Column-level permissions; PII columns excluded from analyst access |
| P6.5 | Build S3 Iceberg bucket module with compliance object lock | Platform Eng | 1 week | P1.3, P1.4 | Bucket supports compliance mode retention; lifecycle transitions configured |
| P6.6 | Build Direct Connect + VPN failover module | Platform Eng | 1.5 weeks | P1.4 | Dual DX circuits + tertiary VPN; Cloud WAN integration tested |
| P6.7 | Build EC2 Bare Metal module for legacy workloads | Platform Eng | 1 week | P1.4 | Dedicated host placement; EBS encryption; licensing-compliant tenancy |
| P6.8 | Validate all advanced modules with 2–3 real workload teams | Platform Eng + Workload Teams | 2 weeks | P6.1–P6.7 | Modules consumed by workload teams; feedback incorporated |

### Gate: Phase 6 Complete
- [ ] AI/ML modules published and validated
- [ ] Data Lakehouse modules published and validated
- [ ] Hybrid/Legacy modules published and validated
- [ ] All modules tested with real workload teams

---

## 9. Phase 7: Platform Operations & Drift Detection (Weeks 20–28)

### Objective
Build automated tooling for ongoing platform operations, drift detection, and cost governance.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P7.1 | Deploy weekly drift scan Lambda across all migrated repos | Platform Eng | 1 week | P2.8 | All repos scanned; drift alerts routed to SNS/Slack |
| P7.2 | Build drift dashboard (central view of drift status across 300+ repos) | Platform Eng | 1.5 weeks | P7.1 | Dashboard shows pass/fail per repo; trending view |
| P7.3 | Deploy Kubecost on EKS for cluster cost allocation | FinOps Eng | 1 week | P1.2 | Kubecost mapping namespace costs; showback reports generating |
| P7.4 | Implement budget threshold alerts (automated notifications to app owners) | FinOps Eng | 1 week | P1.1 | Budgets created per LOB; alerts configured |
| P7.5 | Deploy Prometheus quota usage alerts (AWS API limits, service quotas) | Platform Eng | 1 week | P1.2 | Alerts fire at 80% threshold; proactive increase requests automated |
| P7.6 | Configure automated non-prod shutdown schedules (e.g., 7PM–7AM) | FinOps Eng | 0.5 week | P0.9 | Schedules applied; reverts automated |
| P7.7 | Deploy VPC Flow Logs to centralized OpenSearch | Platform Eng | 1 week | P1.1 | Flow logs aggregated; searchable within 5 minutes |
| P7.8 | Set up OpenTelemetry collector on EKS clusters | Platform Eng | 1.5 weeks | P1.2 | Metrics → Thanos/Prometheus; traces → central telemetry backend |
| P7.9 | Establish FinOps showback report cadence (monthly) | FinOps Eng | 0.5 week | P7.3, P7.4 | First report delivered to LOB owners |

### Gate: Phase 7 Complete
- [ ] Drift detection scanning all repos weekly
- [ ] Drift dashboard visible to platform team
- [ ] Kubecost deployed on all EKS clusters
- [ ] Budget alerts active
- [ ] Quota usage alerts configured
- [ ] Non-prod shutdown schedules enforced
- [ ] VPC Flow Logs searchable
- [ ] OpenTelemetry collecting metrics + traces
- [ ] FinOps showback reporting monthly

---

## 10. Phase 8: Developer Portal & Self-Service (Weeks 22–36)

### Objective
Build an Internal Developer Portal (Backstage) that enables app teams to self-service provision infrastructure without writing HCL directly.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P8.1 | Deploy Backstage instance with scaffolder plugin | Platform Eng | 2 weeks | P0.1 | Backstage accessible to all developers; SSO integrated |
| P8.2 | Create Backstage "Create Microservice" template | Platform Eng | 1.5 weeks | P2.7, P8.1 | Template provisions repo, CI/CD, state backend, IAM roles |
| P8.3 | Create Backstage "Provision S3 Bucket" action (wraps golden module) | Platform Eng | 1 week | P1.3, P8.1 | Action calls golden module; parameters validated via template |
| P8.4 | Create Backstage "Provision DynamoDB Table" action | Platform Eng | 1 week | P1.3, P8.1 | Similar to P8.3 |
| P8.5 | Create Backstage "Provision ECS Service" action | Platform Eng | 1.5 weeks | P1.3, P8.1 | Complex action; includes ALB, task def, service discovery |
| P8.6 | Build portal audit trail (all actions logged to CloudTrail + audit DB) | Security Eng | 1 week | P8.1 | Every portal action traceable to user and timestamp |
| P8.7 | Implement break-glass emergency override (direct Git PR bypass) | Platform Eng | 1 week | P8.1 | Emergency docs; portal can be bypassed via direct repo PR |
| P8.8 | Build architectural variance request workflow in portal | Platform Eng | 1 week | P8.1 | Teams can submit variance requests; routes to platform core review |
| P8.9 | Build app onboarding/offboarding lifecycle pipeline in portal | Platform Eng | 2 weeks | P5.5, P8.1 | Onboarding creates all resources; offboarding tears down, removes DNS, stops billing |
| P8.10 | Pilot portal with 3 app teams; iterate based on feedback | Platform Eng + 3 App Teams | 2 weeks | P8.2–P8.9 | Feedback incorporated; refinements made |

### Gate: Phase 8 Complete
- [ ] Backstage deployed with SSO
- [ ] Microservice creation template active
- [ ] S3, DynamoDB, ECS provisioning actions working
- [ ] Audit trail logging all portal actions
- [ ] Break-glass bypass documented and tested
- [ ] Variance request workflow operational
- [ ] App lifecycle pipeline automated (onboarding + offboarding)
- [ ] Portal pilot completed with 3 teams

---

## 11. Phase 9: App Migration Waves 2–N (Weeks 20–52)

### Objective
Scale migration to all 300+ applications using the refined playbook from Phase 5.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P9.1 | Organize remaining app teams into migration waves (15–20 apps per wave) | Platform Eng + Delivery Leads | 1 week | P5.9 | Migration schedule published; waves grouped by complexity |
| P9.2 | Run migration playbook training for all wave 2 teams | Platform Eng | 1 week | P5.9, P9.1 | All teams trained on golden module consumption |
| P9.3 | Execute wave 2 migration (15–20 apps) — ~2 weeks per wave | Platform Eng + App Teams | 3 weeks | P5.5, P9.2 | Each app follows Phase 5 playbook; zero-diff validated |
| P9.4 | Waves 3–N: execute sequentially, 15–20 apps per wave | Platform Eng + App Teams | 2–3 weeks per wave | P9.3 | Cumulative progress tracked on dashboard |
| P9.5 | Track adoption maturity ladder (L0–L4) across all repos | Platform Eng | Ongoing | P9.3 | Dashboard shows L0→L4 progress; >80% at L3+ by end of year |
| P9.6 | Add Checkov/OPA compliance score to each repo's README badge | Platform Eng | 0.5 week | P4.3 | Badges visible; teams self-correct compliance |
| P9.7 | Monthly compliance report auto-generated and distributed to LOB owners | Security Eng | 1 week | P9.6 | Report shows pass/fail per app; trend graphs |

### Gate: Phase 9 Complete
- [ ] All 300+ apps on golden module pattern (L1+)
- [ ] >80% apps at L3+ maturity (full GitOps + portal-provisioned)
- [ ] Compliance dashboard showing per-repo scores
- [ ] Monthly compliance reports automated

---

## 12. Phase 10: Continuous Improvement & InnerSource (Ongoing)

### Objective
Evolve the platform through community contributions, regular drills, and iterative improvements.

### Tasks

| # | Task | Owner | Est. Effort | Dependencies | Completion Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P10.1 | Establish InnerSource contribution governance model | Platform Eng | 1 week | P1.5 | Contribution PR process documented; review SLA published (24h) |
| P10.2 | Enforce module review SLA (24h for app team PRs to golden modules) | Platform Eng | — | P10.1 | SLA tracked; breaches trigger escalation |
| P10.3 | Conduct quarterly DR failover drill (simulate regional outage) | Platform Eng + Security | Quarterly | P7.8 | 5-minute failover validated; RTO/RPO met; after-action report |
| P10.4 | Monthly Game Days (AWS FIS chaos scenarios) | Platform Eng + Security | Monthly | P4.5 | Scenarios executed; incidents processed through IR playbooks |
| P10.5 | Quarterly module deprecation review; publish deprecation notices | Platform Eng | Quarterly | P1.5 | 90-day notice for breaking changes; migration guides published |
| P10.6 | Semi-annual architecture review; update architectural records | Lead Architect | Bi-annual | P10.5 | Document updated; vendor lock-in exit strategy refreshed |
| P10.7 | Track DORA metrics (deployment frequency, lead time, MTTR) | Platform Eng | Ongoing | — | Metrics dashboard visible to all teams |

### Gate: Phase 10 — Continuous (No End State)
- [ ] InnerSource model active with tracked SLAs
- [ ] Quarterly DR drills completed
- [ ] Monthly chaos drills completed
- [ ] Module deprecation lifecycle managed
- [ ] Architecture reviewed bi-annually
- [ ] DORA metrics collected and visible

---

## 13. Dependency Graph

```
Phase 0: Foundations
    ├── P0.1 AWS Organization & OUs ───────────────────┐
    ├── P0.2 Control Tower ─────────────────────────────┤
    ├── P0.3 IAM Identity Center ───────────────────────┤
    ├── P0.4 OIDC Provider ─────────────────────────────┼──┐
    ├── P0.5 Private Module Registry ───────────────────┤ │
    ├── P0.6 Git Repo Structure ────────────────────────┤ │
    ├── P0.7 Tag Taxonomy ──────────────────────────────┤ │
    ├── P0.8 Compliance Scanning ───────────────────────┤ │
    └── P0.9 Sandbox Accounts ──────────────────────────┘ │
                                                          │
Phase 1: Golden Modules                                  │
    ├── P1.1 Foundation Modules ◄─────────────────────────┘
    ├── P1.2 Shared Platform Modules ◄── P1.1             │
    ├── P1.3 Self-Service Modules ◄── P1.1                │
    ├── P1.4 Specialized Modules ◄── P1.1                 │
    ├── P1.5 Semver Promotion ◄── P1.2, P1.3, P1.4       │
    ├── P1.6 Standard Tags ◄── P0.7                      │
    ├── P1.7 State Backend Module ◄── P1.1               │
    ├── P1.8 OIDC Module ◄── P1.1                        │
    ├── P1.9 Security Baseline Module ◄── P1.1           │
    ├── P1.10 IAM Boundaries Module ◄── P1.1              │
    ├── P1.11 terraform-docs CI ◄── P0.6                 │
    └── P1.12 Renovate ◄── P0.6                          │
                                                          │
Phase 2: CI/CD & OIDC                     ┌───────────────┘
    ├── P2.1 CI/CD Template ◄── P0.4, P1.5               │
    ├── P2.2 OIDC Roles ◄── P1.8, P0.4                  │
    ├── P2.3 Checkov in CI ◄── P2.1                      │
    ├── P2.4 Infracost ◄── P2.1                          │
    ├── P2.5 Branch Protection ◄── P0.6                  │
    ├── P2.6 backend.tf Template ◄── P1.7                │
    ├── P2.7 Repo Template ◄── P1.2, P1.3, P2.6         │
    ├── P2.8 Drift Detection ◄── P1.7, P2.1             │
    └── P2.9 Sandbox Wrapper ◄── P0.9                    │
                                                          │
Phase 3: Account Vending                     ┌───────────┘
    ├── P3.1 AFT Deployment ◄── P0.2                     │
    ├── P3.2 AFT Customizations ◄── P1.7, P1.9, P1.10   │
    ├── P3.3 Account Request Template ◄── P3.2           │
    ├── P3.4 E2E Test ◄── P3.3                           │
    ├── P3.5 State Backend Retrofit ◄── P1.7, P3.2      │
    ├── P3.6 IPAM ◄── P3.2                               │
    └── P3.7 Offboarding Docs ◄── P3.4                   │
                                                          │
Phase 4: Security & Compliance                           │
    ├── P4.1–P4.12 Security Controls ◄── P0.1, P0.2,    │
    │     P1.2, P2.1                                      │
    └── ◄── P4.12 all point to Phase 1+2 deps ──────────┘
                                                          │
Phase 5: Wave 1 Migration                                │
    ├── P5.1–P5.9 Pilot Migration ◄── P1.3, P2.1, P2.2  │
    └── ◄── All deps on Phase 1, 2, 3 ──────────────────┘
                                                          │
Phase 6: Advanced Workloads                  ┌───────────┘
    ├── P6.1–P6.8 AI/ML, Lakehouse, Hybrid ◄── P1.4,    │
    │     P1.2, P1.3                                      │
    └── ◄── Deployed on Phase 1 foundations ────────────┘
                                                          │
Phase 7: Operations                                      │
    ├── P7.1–P7.9 Drift, FinOps, Observability           │
    └── ◄── P2.8, P1.2, P1.1 ──────────────────────────┘
                                                          │
Phase 8: Developer Portal                                │
    ├── P8.1–P8.10 Backstage + Self-Service              │
    └── ◄── P2.7, P1.3, P5.5 ──────────────────────────┘
                                                          │
Phase 9: Scale Migration                                 │
    └── ◄── P5.9, P9.1–P9.7 (iterative with Phase 5) ───┘

Phase 10: Continuous Improvement (no dependencies — ongoing)
```

### Parallel Execution Paths

The following phases can run in parallel to shorten the overall timeline:

| Parallel Group | Phases | Rationale |
| :--- | :--- | :--- |
| **Group A** | Phase 0 + Phase 1 start | Phase 0 foundations are prerequisite to Phase 1 module building |
| **Group B** | Phase 2 + Phase 3 | CI/CD pipelines and account vending are independent work streams |
| **Group C** | Phase 4 + Phase 5 | Security automation runs alongside Wave 1 migration |
| **Group D** | Phase 6 + Phase 7 | Advanced modules and operations tooling can be built simultaneously |
| **Group E** | Phase 8 + Phase 9 | Portal development and Wave 2 migration can overlap |

---

## 14. Resource Estimation

### Team Composition

| Role | Count | Phases Involved | Sourcing |
| :--- | :--- | :--- | :--- |
| Platform Engineering Lead | 1 | All | Dedicated |
| Platform Engineer (IaC) | 3 | 0–9 | Dedicated |
| Security Engineer | 2 | 0, 4, 7, 10 | Shared with Security team |
| FinOps Engineer | 1 | 7, 10 | Shared with FinOps team |
| Developer Portal Engineer | 2 | 8 | Dedicated (weeks 22–36) |
| SRE / Operations Engineer | 1 | 2, 7, 10 | Dedicated |
| App Team Liaison (per wave) | 1 | 5, 9 | Rotating per migration wave |

### Estimated Total Effort

| Phase | Duration | Platform Eng (person-weeks) | Security Eng | Other |
| :--- | :--- | :--- | :--- | :--- |
| Phase 0 | 4 weeks | 8 | 2 | — |
| Phase 1 | 6 weeks | 16 | 1 | — |
| Phase 2 | 7 weeks | 7 | 1 | — |
| Phase 3 | 6 weeks | 7 | — | — |
| Phase 4 | 7 weeks | 4 | 11 | — |
| Phase 5 | 9 weeks | 9 | — | 10 (app teams) |
| Phase 6 | 10 weeks | 10 | — | — |
| Phase 7 | 9 weeks | 6 | 1 | 1 (FinOps) |
| Phase 8 | 14 weeks | 14 | 1 | — |
| Phase 9 | 32 weeks | 12 | — | 60+ (app teams) |
| Phase 10 | Ongoing | 2/quarter | 1/quarter | All teams |
| **Total** | **52 weeks** | **95** | **17** | **~70** |

### Cost Considerations

| Category | Estimated Monthly Cost | Notes |
| :--- | :--- | :--- |
| AWS Control Tower | $0 (included with Organizations) | No additional cost |
| AWS AFT | $0 (Terraform-based) | Lambda + state storage costs negligible |
| Private Module Registry | $0 (self-hosted) or ~$2,000 (Terraform Cloud) | Evaluate Terraform Business vs. self-hosted |
| GitHub Actions Runners | ~$1,500 (self-hosted) | 10 runners for CI/CD across 300+ repos |
| Backstage (self-hosted) | ~$500 (EKS compute + RDS) | Lightweight deployment |
| Kubecost | $0 (free tier) → ~$3,000 (Enterprise) | Free tier sufficient for initial deployment |
| Infracost | $0 (free tier) → ~$2,000 (Team) | Free for up to 100 repos |
| Checkov/OPA | $0 (open source) | Self-managed scanning |
| Infrastructure (S3, DynamoDB, KMS) | ~$300 per account per month | State storage, locking, encryption |
| **Total Platform Overhead** | **~$4,000–$8,000/month** | Excludes application compute costs |

---

## 15. Rollback Strategy

### Per-Phase Rollback Plans

| Phase | Rollback Trigger | Rollback Action | Recovery Time |
| :--- | :--- | :--- | :--- |
| **Phase 2 (CI/CD)** | Pipeline failure blocks all deploys | Revert template changes; fall back to previous template commit | 30 min |
| **Phase 3 (AFT)** | Account vending produces non-compliant account | Destroy misconfigured account via AFT; reprovision | 2 hours |
| **Phase 4 (Security)** | Overly restrictive SCP blocks legitimate operations | Widen SCP; deploy relaxed policy variant | 15 min |
| **Phase 5 (Wave 1 Migration)** | State migration fails / resource is orphaned | Restore from `terraform state pull` backup; revert to old pipeline | 1 hour |
| **Phase 8 (Portal)** | Portal becomes SPoF / unavailable | Activate break-glass: direct Git PR workflow; disable portal route | 5 min |
| **Phase 9 (Scale Migration)** | Cumulative drift from rushed migrations | Halt new waves; focus on drift remediation; extend migration timeline | 1 sprint |

### General Rollback Principles

1. **Every migration has a backup**: `terraform state pull` before any `state mv`
2. **Blue-green state validation**: Validate new state with `plan` showing zero changes before decommissioning old state
3. **Canary migration**: Migrate lowest-risk apps first (internal tools → shared services → business-critical)
4. **Pipeline pinning**: Each app repo pins module versions with `~> x.y` — rollback is a version bump
5. **Document rollback runbook**: For each migration wave, document exact rollback steps and test them

---

## 16. Success Criteria & KPIs

### Architecture Adoption KPIs

| KPI | Measurement | Target (12 months) |
| :--- | :--- | :--- |
| % apps on golden modules | Module consumption in repo `main.tf` | >90% (270+ apps) |
| % apps at L3+ maturity | Portal-provisioned or full GitOps | >80% |
| % apps passing Checkov scan | PR-level scan pass rate | >95% |
| Average migration time per app | From legacy HCL → golden module | <2 weeks |

### Operational KPIs

| KPI | Measurement | Target |
| :--- | :--- | :--- |
| State lock conflicts per week | Count of DynamoDB lock contention | <5 |
| Blast radius incidents per quarter | Incidents affecting >1 app | 0 |
| Drift detection coverage | % of repos scanned weekly | 100% |
| Mean time to drift remediation | Alert → plan verified clean | <24 hours |
| CI/CD pipeline success rate | % of plan/apply runs succeeding | >99% |

### Security KPIs

| KPI | Measurement | Target |
| :--- | :--- | :--- |
| Critical vulns in production | Trivy scan results | 0 |
| Compliance audit pass rate | Checkov/OPA score | >95% |
| Time to contain security incident | SSM playbook trigger → isolation | <15 minutes |
| Secrets in state files | `sensitive = true` compliance | 0 |

### Developer Experience KPIs

| KPI | Measurement | Target |
| :--- | :--- | :--- |
| Time to provision new microservice | Portal request → running infrastructure | <30 minutes |
| PR merge time (app IaC changes) | PR opened → merged | <4 hours |
| Module contribution PR review time | PR submitted → reviewed | <24 hours (SLA) |
| Developer satisfaction score | Survey score (1–5) | >4.0 |

---

## 17. Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Phase |
| :--- | :--- | :--- | :--- | :--- | :--- |
| R1 | Portal becomes a bottleneck/SPoF | Medium | High | Circuit breakers; fallback to direct Git PRs; break-glass docs | 8 |
| R2 | Golden modules lag behind app team needs | High | High | InnerSource contribution model; 24h review SLA | 10 |
| R3 | SSM parameter drift between infrastructure tiers | Medium | Medium | SSM versioning; dependency updates trigger CI refreshes | All |
| R4 | OIDC token scope sprawl across repos | Medium | High | Pin sub claims; separate Plan/Apply roles; audit quarterly | 2 |
| R5 | State migration data loss during monolith split | Low | Critical | Automated `state pull` backup before every migration; blue-green validation | 5, 9 |
| R6 | Module registry supply chain poisoning | Low | High | Private registry only; verify upstream signatures; Cosign | 1, 4 |
| R7 | CI/CD execution lock-in halts local testing | Medium | Medium | Developer sandbox mode with LocalStack/dedicated accounts | 2 |
| R8 | Provider version drift across 300+ repos | Medium | Medium | Renovate auto-updates; CI rejects unsupported versions | 1, 9 |
| R9 | Cross-region plan latency (5–10 min) | Medium | Low | Region-pinned state files; parallel plan execution in CI | 7 |
| R10 | Team resistance to migration | Medium | High | Early pilot wins; training; show clear benefits (faster deploys, less toil) | 5, 9 |

---

## Appendix A: Maturity Adoption Ladder

Each application repository progresses through these levels over the migration:

```
Level 0: Raw HCL (Legacy)
    └── Status: Compliance scanning only (Checkov/OPA)
    └── Action: Enroll in training; schedule migration wave

Level 1: Golden Module Consumption
    └── Status: Team completes onboarding training
    └── Action: Refactor main.tf to consume golden modules
    └── Validation: terraform plan shows zero diff with legacy

Level 2: Full GitOps Pipeline
    └── Status: Automated plan/apply via CI/CD (OIDC-authenticated)
    └── Action: Migrate state to per-app backend; enable CI/CD
    └── Validation: No local applies; all changes through PR pipeline

Level 3: Portal-Provisioned
    └── Status: Zero-touch deployment via Backstage
    └── Action: Onboard app to Developer Portal
    └── Validation: New resources provisionable through portal UI

Level 4: Policy-as-Code Gated
    └── Status: Automated compliance certification
    └── Action: All changes pre-validated by OPA/Checkov
    └── Validation: Compliance score >95%; audit-ready at any time
```

---

## Appendix B: Migration Wave Schedule Template

| Wave | Duration | Apps | Complexity | Owner | Key Risks |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Wave 1 (Pilot) | Weeks 14–22 | 5–10 | Low-Med | Platform Eng + Pilot Teams | R5, R10 |
| Wave 2 | Weeks 22–25 | 15–20 | Low | Platform Eng + App Teams | R10 |
| Wave 3 | Weeks 25–28 | 15–20 | Low-Med | Platform Eng + App Teams | R8 |
| Wave 4 | Weeks 28–31 | 15–20 | Med | Platform Eng + App Teams | R3, R8 |
| Wave 5 | Weeks 31–34 | 15–20 | Med-High | Platform Eng + App Teams | R3, R5 |
| Waves 6–N | Weeks 34–52 | ~15 per wave | Mixed | Platform Eng + App Teams | All |

**Prioritization:**
- **Wave 1**: Internal tools, non-critical services (lowest blast radius)
- **Waves 2–3**: Standard CRUD services with simple infrastructure
- **Waves 4–5**: Stateful services, moderate complexity
- **Waves 6+**: Business-critical, high-complexity, AI/ML, legacy systems

---

## Appendix C: Phase Dependency Matrix

| Phase | Depends On | Provides To | Can Run In Parallel With |
| :--- | :--- | :--- | :--- |
| Phase 0 | — | Phases 1, 2, 3, 4 | — |
| Phase 1 | Phase 0 | Phases 2, 5, 6, 8 | Phase 3 (partial overlap) |
| Phase 2 | Phase 0, Phase 1 | Phases 4, 5, 7, 9 | Phase 3 |
| Phase 3 | Phase 0, Phase 1 | Phase 5, 9 | Phase 2, Phase 4 |
| Phase 4 | Phase 0, Phase 1, Phase 2 | Phase 5, 7 | Phase 3, Phase 5 |
| Phase 5 | Phase 1, Phase 2, Phase 3, Phase 4 | Phase 9 | Phase 4, Phase 6, Phase 7 |
| Phase 6 | Phase 1 | Phase 9 | Phase 5, Phase 7, Phase 8 |
| Phase 7 | Phase 1, Phase 2, Phase 4 | Phase 10 | Phase 5, Phase 6, Phase 8 |
| Phase 8 | Phase 1, Phase 2, Phase 5 | Phase 9, Phase 10 | Phase 6, Phase 7 |
| Phase 9 | Phase 5, Phase 1 | Phase 10 | Phase 8 |
| Phase 10 | Phase 7, Phase 8, Phase 9 | — | — |

---

## Appendix D: Key Tools & Versions

| Tool | Version | Purpose | Managed By |
| :--- | :--- | :--- | :--- |
| Terraform | >= 1.9.0 | IaC provisioning | Platform Eng |
| OpenTofu | Alternative | IaC provisioning (Terraform OSS fork) | Platform Eng (eval) |
| AWS Control Tower | Latest | Multi-account governance | Platform Eng |
| AWS Account Factory for Terraform (AFT) | Latest | Automated account vending | Platform Eng |
| GitHub Actions | — | CI/CD execution | Platform Eng |
| Checkov | Latest | IaC security scanning | Security Eng |
| OPA / Conftest | Latest | Policy-as-Code | Security Eng |
| Infracost | Latest | Cost estimation | FinOps Eng |
| Trivy | Latest | Container vulnerability scanning | Security Eng |
| Cosign | Latest | Container image signing | Security Eng |
| Kyverno | Latest | Kubernetes admission controller | Security Eng |
| Falco / Tetragon | Latest | Runtime security | Security Eng |
| Backstage | Latest | Developer Portal | Platform Eng |
| Kubecost | Latest | Kubernetes cost allocation | FinOps Eng |
| Renovate | Latest | Automated dependency updates | Platform Eng |
| terraform-docs | Latest | Auto-generated module docs | Platform Eng |
| OpenTelemetry | Latest | Metrics, traces, logs collection | Platform Eng |
| ArgoCD | Latest | GitOps deployment | Platform Eng |
| Karpenter | Latest | Kubernetes cluster autoscaler | Platform Eng |

---

## Appendix E: Change Log

| Version | Date | Author | Changes |
| :--- | :--- | :--- | :--- |
| 1.0.0 | 2026-06-16 | Implementation Lead | Initial implementation plan based on `large_org_iac_architecture.md` v2.0.0 |
