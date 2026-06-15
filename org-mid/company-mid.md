# Company-Mid: Infrastructure Design & Assumptions

> This document captures a mid-size company's AWS infrastructure requirements, assumptions, architecture decisions, and terraform implementation plan. It builds on patterns established in `org-small` but scales for multi-account, multi-region, and multi-team operations.

---

## 1. Company Profile & Assumptions

### 1.1 Business Context

| Assumption | Detail |
|---|---|
| **Company size** | ~100-500 employees, ~20-40 engineers (backend, frontend, data, ML, platform/SRE) |
| **Industry** | SaaS / Digital Product (Fintech, HealthTech, E-commerce, or B2B Platform) |
| **Stage** | Series B / C — profitable or well-funded; scaling fast with multiple product lines |
| **Team maturity** | Dedicated platform/SRE team (3-5 engineers); separate security/compliance team (1-2) |
| **Compliance needs** | SOC 2 Type II + PCI DSS Level 1 or HIPAA; ISO 27001 in-progress |
| **Budget** | ~$35k-$60k / month on AWS across all accounts (All-inclusive target) |
| **Regions** | Primary: `us-east-1`; DR: `us-west-2`; Edge: CloudFront POPs global. |
| **Deployment frequency** | Multiple deploys per day per service; CI/CD with approval gates for prod |

### 1.2 Team Structure, Decision Ownership & RACI

| Function | Platform/SRE | Security/Compliance | Backend Squads | Data/ML Team |
|---|---|---|---|---|
| **Core Network & TGW Routing** | **Accountable (A)** | Consulted (C) | Informed (I) | Informed (I) |
| **EKS Control Plane & Add-ons** | **Accountable (A)** | Consulted (C) | Informed (I) | Informed (I) |
| **IAM Permission Boundaries & SCPs**| Consulted (C) | **Accountable (A)** | Informed (I) | Informed (I) |
| **Secrets Engine & Encryption Keys**| **Accountable (A)** | Consulted (C) | Responsible (R) | Responsible (R) |
| **Database Operations (Aurora/Redis)**| Responsible (R) | Informed (I) | **Accountable (A)** | Informed (I) |
| **Data Lake & Redshift ETL** | Consulted (C) | Consulted (C) | Informed (I) | **Accountable (A)** |
| **Microservice Helm Charts & Apps** | Consulted (C) | Informed (I) | **Accountable (A)** | Responsible (R) |

*Legend: R = Responsible, A = Accountable, C = Consulted, I = Informed*

### 1.3 Workload Assumptions

| Assumption | Detail |
|---|---|
| **Application types** | 5+ distinct workload families — see Section 2 |
| **Traffic profile** | Heavy: 100k-1M+ daily active users; global distribution; predictable + event-driven spikes |
| **Data sensitivity** | PII/PHI/payment data; multi-tenant isolation required; data residency constraints |
| **Tech stack** | Go/Rust/Node.js/Python backends, React/Next.js frontend, PostgreSQL/Aurora, DynamoDB, Kafka, Redis |
| **Containerization** | Fully containerized; EKS primary compute; some Lambda for event-driven workloads |
| **Observability** | OpenSearch Serverless + Thanos (remote-write) + Prometheus/Grafana + X-Ray + PagerDuty |
| **ML/AI** | SageMaker for training + EKS for inference; GPU instances for model serving |

### 1.4 Prerequisites & Current State
The project assumes the following starting parameters:
1. **AWS Organizations**: A parent AWS organization exists, but no sub-accounts or OUs have been configured.
2. **Domain/DNS**: The primary domain `company-mid.io` is registered in an external registrar; Route53 delegation needs to be configured during Phase 3.
3. **Identity Provider**: An Okta tenant exists with user groups mapped for SRE, Security, and Developers. SCIM synchronization to AWS IAM Identity Center will be configured.
4. **Funding/Approvals**: Budget has been pre-approved for AWS Shield Advanced flat rate ($3,000/mo) under the corporate security budget.

### 1.5 Out of Scope (What We Are Not Building & Why)
The following items are intentionally excluded from Phase 1 to reduce operational complexity and avoid resource-draining overhead:

- **Service Catalog**: SRE will not provide automated developer service scaffolding (e.g., Backstage) in this phase. *Rationale:* Team size (3-5 SREs) is too small to build and maintain internal developer portals; focus remains on baseline compute and network stability.
- **Multi-Cloud Architecture**: No support for running workloads on GCP or Azure. All services are pinned to AWS. *Rationale:* Multi-cloud increases operational complexity exponentially and forces "lowest common denominator" engineering.
- **Active-Active Multi-Region Database**: Workloads are active-passive (us-east-1 primary, us-west-2 backup). *Rationale:* Multi-region active-active database configurations introduce high latency, conflict-resolution risks, and double infrastructure costs. Active-passive with Aurora Global replication (<1s lag) easily satisfies our 5-minute RTO target.
- **Database Migration Pipeline**: Schema migrations (e.g., Liquibase/Flyway) are managed by individual squads and excluded from this infrastructure build.
- **Global Data Sovereignty (GDPR EU-only Isolation)**: Replicating this stack in EU regions is deferred. *Rationale:* Business operates primarily in NA in Phase 1; building an EU enclave is deferred until business growth warrants the overhead.
- **Corporate Office Connectivity**: Direct Connect and corporate IPSec VPN tunnels to office buildings are deferred to Phase 2; engineers use AWS Client VPN to access the Shared Services VPC.
- **Formal Data Classification Matrices & Pen-Test Scheduling**: Detailed matrices and schedule tables are managed in the security wiki rather than the infrastructure code blueprint.

---

## 2. Workload Deployment Types

The company runs **5 distinct workload families**, each with different infrastructure needs:

### 2.1 Workload A: Customer-Facing API (EKS)
| Aspect | Detail |
|---|---|
| **What** | Stateless REST/gRPC APIs (user service, payment, billing, notifications) |
| **Deployment** | EKS with Karpenter auto-scaling, multiple services per cluster |
| **Cluster topology** | 3 EKS clusters: `platform` (shared services), `customer-api` (customer-facing), `internal` (admin tools) |
| **Instance types** | Mix: `m7i.large` (general), `c7i.xlarge` (compute), `r7i.large` (memory) via Karpenter |
| **Scaling** | HPA (CPU/memory + custom metrics), Karpenter node provisioning |
| **Ingress** | ALB Ingress Controller + NGINX Ingress; API Gateway for external-facing APIs |
| **Service mesh** | Istio (mTLS, traffic splitting, observability) |

### 2.2 Workload B: Event-Driven & Async Processing
| Aspect | Detail |
|---|---|
| **What** | Background jobs, event processing, data pipelines, webhook delivery |
| **Compute** | Mix of EKS (Kubernetes jobs/cronjobs) and AWS Lambda (ECS Fargate has been retired to standardize compute stacks) |
| **Messaging** | Amazon MSK (Kafka) for event streaming, SQS for job queues, SNS for notifications |
| **Orchestration** | Step Functions for complex workflows, MWAA (Airflow) for data pipelines |
| **Lambda** | ~20-30 functions; Node.js/Python; some with container images (up to 10GB) |
| **Storage** | S3 + EFS for shared state; DynamoDB for job metadata |

### 2.3 Workload C: Data & Analytics Platform
| Aspect | Detail |
|---|---|
| **What** | Data warehouse, real-time analytics, BI dashboards, ML feature store |
| **Compute** | EKS (analytics-spark cluster) for Spark jobs + SageMaker for ML + Redshift for warehousing |
| **Storage** | S3 data lake (Iceberg/Delta Lake format), Redshift RA3 nodes with managed storage |
| **Streaming** | Amazon MSK + Kinesis Data Analytics for real-time processing |
| **Orchestration** | MWAA (Airflow) with 50+ DAGs; Step Functions for simpler workflows |
| **ML** | SageMaker Studio + training jobs (GPU instances) + EKS inference (Karpenter + GPU nodes) |
| **Reporting** | Redshift → QuickSight; OpenSearch for log analytics |

### 2.4 Workload D: Frontend & Edge
| Aspect | Detail |
|---|---|
| **What** | Next.js/React SPA, static assets, A/B testing, edge logic |
| **CDN** | CloudFront with multiple origins (S3 + ALB + Lambda@Edge) |
| **Edge compute** | Lambda@Edge + CloudFront Functions for header manipulation, URL rewrites, auth checks |
| **Hosting** | S3 + CloudFront for static assets; ALB + EKS for SSR (Next.js) |
| **WAF** | AWS WAF with managed rule groups + rate limiting + bot control + geo-blocking |
| **DNS** | Route53 with latency-based routing + health checks; CloudFront as global entry point |
| **DDoS** | AWS Shield Advanced on CloudFront + ALB |

### 2.5 Workload E: Internal Tools & Admin
| Aspect | Detail |
|---|---|
| **What** | Admin dashboards, internal APIs, CI/CD runners, artifact storage |
| **Compute** | EKS (internal cluster) + some EC2 for legacy tools |
| **Auth** | Internal SSO (Okta/Azure AD) via IAM Identity Center; OAuth2 proxy on all internal tools |
| **CI/CD** | Self-hosted GitHub Actions runners on EKS (Karpenter-scaled); CodePipeline for Terraform |
| **Artifacts** | ECR (container images), CodeArtifact (packages), S3 (build artifacts) |
| **Secrets** | Standardized dynamic credentials managed centrally via AWS Secrets Manager (See ADR-01) |

---

## 3. Multi-Account Architecture

### 3.1 Account Structure

```
Company-Mid AWS Organization
├── Management Account (root)
│   ├── CloudTrail (org trail)
│   ├── AWS Config (org aggregator)
│   ├── Security Hub (org admin)
│   ├── Budgets + Cost Explorer
│   └── IAM Identity Center
│
├── Security Account (ou-security)
│   ├── GuardDuty (delegated admin)
│   ├── Inspector (delegated admin)
│   ├── Macie (S3 data discovery)
│   ├── CloudTrail logs (S3 bucket, org trail)
│   ├── AWS Config rules + conformance packs
│   ├── KMS multi-region keys
│   └── Backup vault (cross-account backup)
│
├── Log Archive Account (ou-infrastructure)
│   ├── S3 bucket (CloudTrail + Config + VPC Flow Logs)
│   ├── S3 bucket (access logs for all ALBs/S3s)
│   ├── Glacier + Object Lock (compliance mode, 7-year retention)
│   └── OpenSearch (log analytics, cross-account)
│
├── Shared Services Account (ou-infrastructure)
│   ├── Transit Gateway (shared TGW)
│   ├── Route 53 (shared zones)
│   ├── ACM (private CA + public certs)
│   ├── ECR (cross-account registry - See ADR-05)
│   ├── CodeArtifact
│   ├── GitHub Actions runners (EKS)
│   └── VPC (centralized egress VPC - See ADR-02)
│
├── Dev Account (ou-workloads)
│   ├── EKS clusters (dev)
│   ├── RDS/Aurora (dev)
│   ├── MSK (dev)
│   ├── ElastiCache (dev)
│   └── Everything else (dev)
│
├── Staging Account (ou-workloads)
│   ├── Same as dev but production-like sizing
│   └── Pre-production integration testing
│
├── Prod Account (ou-workloads)
│   ├── EKS clusters (prod — 2x: customer-api and internal)
│   ├── Aurora Global Database
│   ├── MSK (prod, multi-AZ)
│   ├── ElastiCache (prod, cluster mode)
│   └── All production user-facing workloads (OLTP)
│
└── Data Analytics Account (ou-workloads) (See ADR-03)
    ├── Data lake (S3 + Iceberg)
    ├── EMR / Spark on EKS (Dedicated analytics-spark EKS cluster)
    ├── SageMaker (training + batch inference)
    ├── MWAA (Airflow)
    └── Redshift Analytical Cluster
```

### 3.2 Service Control Policies (SCPs)

| Policy | Effect | Target |
|---|---|---|
| Deny leaving Organizations | `Deny` | Root OU |
| Deny disabling CloudTrail/Config | `Deny` | All accounts |
| Deny root user actions (key creation, sign-in) | `Deny` | All accounts |
| Deny public S3/RDS/Redshift access | `Deny` | Workload accounts |
| Deny modifying VPC Flow Logs | `Deny` | Production OU |
| Deny disabling GuardDuty/Security Hub | `Deny` | All accounts |
| Require KMS encryption on all resources | `Deny` | Workload accounts |
| Require IMDSv2 on EC2 | `Deny` | All accounts |
| Restrict instance types (no XL/2XL in dev) | `Deny` | Dev account |
| Deny IAM access key creation (humans) | `Deny` | All accounts (excl. break-glass) |

### 3.3 Cross-Account Networking

```
                    ┌─────────────────────┐
                    │  Management Account   │
                    │  AWS Organizations    │
                    └─────────────────────┘

                    ┌─────────────────────┐
                    │  Shared Services VPC  │
                    │  (us-east-1)          │
                    │  ┌─────────────────┐ │
                    │  │ TGW (hub)       │ │
                    │  └──────┬──────────┘ │
                    └─────────┼────────────┘
                               │ TGW Peering
               ┌───────────────┼───────────────┐
               │               │               │
      ┌────────▼──────┐ ┌─────▼───────┐ ┌─────▼──────┐
      │ Dev VPC        │ │ Staging VPC  │ │ Prod VPC    │
      │ 10.10.0.0/16   │ │ 10.20.0.0/16 │ │ 10.30.0.0/16│
      │ TGW attachment │ │ TGW attach   │ │ TGW attach  │
      └────────────────┘ └──────────────┘ └─────────────┘
                               │
                      ┌────────▼────────┐
                      │ Data Analytics    │
                      │ VPC (us-east-1)  │
                      │ 10.40.0.0/16     │
                      │ TGW attachment   │
                      └─────────────────┘

DR Region (us-west-2):
                      ┌──────────────────┐
                      │ Prod DR VPC       │
                      │ 10.31.0.0/16      │
                      │ TGW attach (DR)   │
                      └──────────────────┘
```

---

## 4. Network Architecture (per Account)

### 4.1 VPC Design (Production Account Example)

```
10.30.0.0/16 — Production VPC
├── Public Subnets (/24 each, 2 AZs)
│   10.30.1.0/24 (us-east-1a) — CloudFront origin ALB
│   10.30.2.0/24 (us-east-1b) — CloudFront origin ALB
│
├── Private Subnets (/20 each, 3 AZs)
│   10.30.16.0/20 (us-east-1a) — EKS platform pods / nodes
│   10.30.32.0/20 (us-east-1b) — EKS customer-api pods / nodes
│   10.30.48.0/20 (us-east-1c) — EKS internal pods / nodes
│
├── Data Subnets (/22 each, 3 AZs)
│   10.30.64.0/22 (us-east-1a) — RDS/Aurora, ElastiCache, MSK
│   10.30.68.0/22 (us-east-1b) — RDS/Aurora, ElastiCache, MSK
│   10.30.72.0/22 (us-east-1c) — RDS/Aurora, ElastiCache, MSK
│
├── Endpoint Subnets (/24 each, 2 AZs)
│   10.30.96.0/24 (us-east-1a) — VPC Endpoints (SSM, S3 Gateway, DynamoDB, ECR, KMS)
│   10.30.97.0/24 (us-east-1b) — VPC Endpoints (SSM, S3 Gateway, DynamoDB, ECR, KMS)
│
└── TGW Attachment Subnets (/28 each, 2 AZs)
    10.30.112.0/28 (us-east-1a) — Transit Gateway VPC attachment
    10.30.112.16/28 (us-east-1b) — Transit Gateway VPC attachment
```

*Note: Egress routing is handled centrally via the Shared Services Egress VPC to minimize NAT Gateway hourly costs. (See ADR-02).*

### 4.2 Connectivity Matrix & TGW Bandwidth Safeguards

| Source | Destination | Mechanism | Bandwidth |
|---|---|---|---|
| Workload VPC → Shared Services | TGW attachment | TGW route table | Up to 50 Gbps (per attachment) |
| Workload VPC → Internet (egress) | TGW → Egress VPC | Shared Services Central NAT | Up to 45 Gbps per NAT GW |
| VPC → S3/DynamoDB | Gateway Endpoints | Free, no NAT needed | Up to 100 Gbps |
| VPC → Other AWS services | Interface Endpoints (PrivateLink) | Per-service endpoints | 1-10 Gbps per ENI |
| Cross-region (us-east-1 ↔ us-west-2) | TGW inter-region peering | TGW peering | 1-10 Gbps |

- **TGW Bandwidth Limit Monitoring**: Transit Gateway attachments are capped at 50 Gbps. SRE configures a CloudWatch Metric Alarm triggers a warning to Slack when any attachment bandwidth utilization exceeds 40 Gbps (80% capacity) for 5 consecutive minutes.

### 4.3 Network Security, VPC Flow Logs & Microsegmentation
To protect internal traffic, we enforce:
- **VPC Flow Logs**: Enabled on all VPC subnets. Traffic records are streamed to CloudWatch Logs with a 7-day retention period, then archived to the Log Archive S3 bucket for compliance auditing (SOC 2, PCI).
- **Security Groups (SG) Tiering**:
  * `edge-sg`: Applied to public ALBs. Restricts ingress to CloudFront IPs only.
  * `app-sg`: Applied to EKS worker nodes. Restricts ingress to public ALBs and internal VPC ranges.
  * `data-sg`: Applied to Aurora, Redis, and MSK brokers. Ingress restricted strictly to specific `app-sg` groups and backend namespaces.

---

## 5. DNS, SSL, & CDN

### 5.1 CloudFront Distribution Layout & WAF Rules Lifecycle

WAF managed rule updates are synchronized via AWS Firewall Manager. False positives are triaged by the Security Team using a staging-first WAF rule evaluation profile, propagating rules to production only after 24 hours of anomaly-free log collection in dry-run mode.

```
CloudFront Distribution
├── Default behavior (*)
│   ├── Origin: ALB (EKS customer-api)
│   ├── Viewer protocol: Redirect HTTP→HTTPS
│   ├── Cache policy: CachingDisabled (dynamic API)
│   ├── WAF: Enabled (Managed SQLi/XSS + Bot Control + Rate-Limiting)
│   └── Lambda@Edge: Utilized for auth verification & header enrichment
│
├── Path: /static/*
│   ├── Origin: S3 (static assets bucket)
│   ├── Cache policy: CachingOptimized (1yr TTL)
│   └── Origin access: OAC (Origin Access Control)
│
└── Path: /_next/*
    ├── Origin: ALB (EKS frontend service — SSR)
    └── Cache policy: CachingOptimizedForUncacheableOrigin
```

### 5.2 DNS Routing & Active Failover
- **Route53 DNS Failover**: The primary hosted zone `*.company-mid.io` uses Route53 Latency-Based routing under normal conditions. 
- **Health Checks**: DNS health checks monitor primary region public endpoints. If the primary region goes offline, Route53 automatically redirects client traffic to the secondary DR region (`us-west-2`) endpoints.

---

## 6. IAM Architecture

### 6.1 IAM Principles

- **No Long-lived Keys**: Humans log in exclusively using AWS IAM Identity Center mapped to Okta.
- **Machine Access via OIDC**: GitHub Actions runners log in to AWS using scoped OIDC roles.
- **Least Privilege boundaries**: EKS workloads use Service-Account scoped roles (IRSA) restricted by resource-path prefixes.

---

## 7. Kubernetes Architecture (EKS)

### 7.1 Namespace-Level Isolation & Multi-Tenancy
Multiple squads share the same EKS clusters. We enforce:
- **Network Policies**: Cilium network policies deny cross-namespace pod communication by default.
- **Resource Quotas**: Hard CPU/Memory resource limits are enforced per namespace.
- **RBAC**: Kubernetes cluster access is scoped via Okta group memberships mapped to specific Kubernetes RoleBindings.
- **Admission Controller Policy**: Deployed **Kyverno** to validate, mutate, and block non-compliant pod manifests (e.g., blocking root containers).

### 7.2 EKS Lifecycle Upgrade Cadence
To prevent tech debt, we enforce a flexible 4-to-6-month upgrade window:
```
Development Cluster Upgrade ──► Staging Cluster Upgrade (2 weeks later) ──► Production Cluster Upgrade (3 weeks later)
```
Upgrade workflow covers Kubernetes version (e.g., 1.30 to 1.31), Karpenter versions, Cilium CNI, and Istio sidecar injectors concurrently.

### 7.3 Karpenter Safeguards & Config (See ADR-04)
To mitigate runaway scaling bills, Karpenter limits are restricted:
```yaml
spec:
  limits:
    cpu: 128
    memory: 512Gi
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: [on-demand, spot]
```
*Note: **Cluster Autoscaler** is retained solely as a fallback configuration for the managed node groups hosting EKS core system pods.*

---

## 8. Data Layer, Backups & Secrets Management

### 8.1 Secrets Rotation & Storage Strategy
Dynamic secrets are stored in AWS Secrets Manager and synced to EKS using the External Secrets Operator (ESO). (See ADR-01).

- **Rotation Cadence**: Database credentials rotate automatically every 30 days via AWS Lambda rotation functions.
- **Testing rotation**: Automated integration tests execute weekly in the staging environment to verify application connections under rotated credentials.
- **Secrets Rotation Failure Handling**: If a rotation Lambda fails, an alert is triggered in CloudWatch and forwarded to the PagerDuty SRE schedule. The rotation system falls back to the previous active key version (retained for a 24-hour grace window) to prevent immediate application outage while SRE triages.

### 8.2 AWS Backup Strategy (Gap G7)
AWS Backup manages snapshots across accounts using centralized rules:
- **RDS/Aurora**: Daily snapshots retained for 35 days, replicated to the Security account Backup vault in `us-west-2`.
- **EFS Volumes**: Daily incremental backups with 30-day retention.
- **S3 Data Lake**: Versioning enabled with Cross-Region Replication (CRR) and Object Lock (Compliance mode) on log buckets.

### 8.3 S3 Bucket Layout

| Bucket Name | Purpose | Retention | Cross-Region Replication (DR) |
|---|---|---|---|
| `company-mid-prod-app-logs` | VPC Flow, ALB, CloudFront logs | 7yr (Glacier transition after 30d) | Enabled (us-west-2) |
| `company-mid-prod-data-lake` | Raw and analytics parquet data | Indefinite | Enabled (us-west-2) |
| `company-mid-prod-backups` | DB snapshots and state files | 35d | Enabled (us-west-2) |
| `company-mid-prod-static-assets` | Static client-side artifacts | Indefinite | Enabled (us-west-2) |
| `company-mid-prod-artifacts` | Built service binaries and charts | 90d | None |
| `company-mid-prod-cloudtrail` | Org-level CloudTrail audits | 7yr (Object Locked) | None (Security Account) |
| `company-mid-prod-access-logs` | Target server logging | 90d | None |

---

## 9. CI/CD Architecture & Developer Experience

### 9.1 Developer Deployment Workflow
```
Developer Git Push ──► PR Lint & Test ──► Staging Auto-Deploy ──► Integration Tests ──► Prod Manual Gate ──► Canary Rollout
```
1. **Local Dev**: Mocked dependencies using **LocalStack Pro**. Licenses for ~40 developers (~$400/mo) are managed centrally by SRE and accounted for in the external integration budget.
2. **PR Stage**: Semgrep SAST scans, unit tests, and Docker image build.
3. **Environment Promotion**: Clean builds deploy automatically to Dev and Staging. Production deployments require a Slack-approved manual gate, deploying in 10% -> 50% -> 100% traffic increments using Istio.

### 9.2 Container Image Vulnerability Lifecycle
1. **ECR Scanning**: ECR images are scanned on-push using Amazon Inspector.
2. **Blocking policy**: Container image builds fail automatically if any **Critical** or **High** CVEs are detected.
3. **Running Vulnerabilities**: Daily Inspector runs scan running pods. If a running container is flagged with a Critical CVE, an alert goes to PagerDuty. Workload owners have 48 hours to patch and redeploy before SRE forces pod termination.

### 9.3 Self-Hosted GitHub Actions Runner Security
- **Isolation**: Runner pods run as ephemeral, single-use containers within a dedicated EKS namespace (`runners`).
- **Network Segmentation**: Runner pods are blocked from accessing other internal VPC endpoints and database subnets.
- **Least Privilege**: Runner pods assume dynamic AWS roles via OIDC with policies restricted to ECR push and S3 cache paths.

---

## 10. Observability & Monitoring

### 10.1 Thanos Metrics Storage & Costing (Gap G8)
Prometheus metrics are remote-written to Thanos.
- **Storage**: Metric chunks are consolidated in an S3 bucket in the Log Archive account with a 13-month lifecycle policy.
- **Thanos Querier**: Deployed as an EKS service, querying S3 storage directly. Cost is estimated at ~$550/mo ($150 S3 storage + $400 querier compute).
- **Distributed Tracing**: Distributed tracing across EKS microservices is supported using **AWS X-Ray** integrations.

### 10.2 Service Level Objectives (SLOs) (Gap G11)

| Service | SLO Target | Metric | Alerting Trigger |
|---|---|---|---|
| Customer API (Read) | **99.9%** | p99 Latency < 200ms | Burn rate > 5% over 1h (Critical Page) |
| Customer API (Write) | **99.5%** | p99 Latency < 500ms | Burn rate > 5% over 1h (Critical Page) |
| Payment API | **99.99%** | Status code 200 Success | Burn rate > 1% over 30m (Critical Page) |
| Search API | **99.0%** | p99 Latency < 1s | Burn rate > 10% over 6h (Jira Ticket) |
| Data Ingestion Pipeline | **99.9%** | Freshness < 5 min | Data lag > 10 min over 1h (Warn Page) |

---

## 11. Security, Incident Response & Compliance

### 11.1 Data Residency & Sovereignty (Gap G5)
- All client PII data is restricted to `us-east-1` and replication is limited to `us-west-2`.
- EU GDPR compliance is deferred. If required in future, a dedicated region OU and VPC structure will be created under the AWS Organizations root.

### 11.5 Incident Response & Change Management Guardrails
To enforce operational safety:
- **Incident Classifications & Rotation**: A primary and secondary SRE are assigned weekly to the PagerDuty rotation. 
  * **P1 Incidents** (API downtime, database failover) trigger immediate SRE phone calls. If unacknowledged within 5 minutes, alerts escalate to the Lead SRE.
  * **P2 Incidents** (High replica lag, CPU warnings) alert SRE via Slack.
- **Terraform Change Management**:
  * Direct updates to the `terraform-infra` repository are blocked. All changes must go through a PR.
  * PR checks run automated `tflint`, security parsing, and staging Terratests.
  * Staging and Production merges require a peer SRE code review and approval. Production applies are restricted to scheduled maintenance windows.

---

## 12. Disaster Recovery & Tabletop validation

### 12.1 RTO/RPO Targets

| Workload | RTO | RPO | DR Strategy |
|---|---|---|---|
| Customer API | 5 min | <1s | Aurora Global Database + DNS failover |
| Data platform | 4 hours | 1 hour | Cross-region backup replication |

### 12.2 DR Verification Tabletop Cadence
- **Quarterly Automated Restoration**: SRE schedules automated weekly restoration checks for database snapshots to staging environments.
- **Bi-Annual DR Drills**: Active simulation of regional outages. Aurora database promotion to `us-west-2` and DNS record redirection are tested under supervision.

---

## 13. Cost Estimate (Monthly - All-Inclusive)

### 13.1 AWS Cost Breakdown per Service (Production Environment Sizing)

| Service | Configuration | Estimated Cost |
|---|---|---|
| **EKS Clusters (Prod/Staging/Shared/Data)**| 6 control planes + Karpenter nodes | ~$3,800 |
| **Aurora Global DB** | 1 writer + 4 readers (r7g.large) | ~$2,400 |
| **MSK Kafka** | 3 brokers (m7g.large) | ~$600 |
| **Redshift** | 4 RA3.xlplus nodes (Analytics Account) | ~$2,600 |
| **Thanos Metrics & Log Archive S3** | Thanos S3 + OpenSearch Serverless logs | ~$1,350 |
| **Centralized Egress Network** | Transit Gateway processing + Central NAT | ~$1,100 |
| **WAF + Shield Advanced** | Shield flat fee ($3,000/mo) + WAF rules | ~$3,150 |
| **S3 & EBS Storage + Backups** | 50TB storage + CRR + AWS Backup | ~$1,600 |
| **Total Production AWS Spend** | | **~$19,600/mo** |

### 13.2 Overall Account & Support Budget Summary

| Category | Description / Coverage | Monthly Run-rate |
|---|---|---|
| **Production Account** | All customer-facing workloads + OLTP DBs | ~$15,500 |
| **Data Analytics Account** | Redshift, MWAA, Iceberg lake, EKS Spark | ~$2,500 |
| **Staging Account** | Pre-production environment (50% of prod sizing) | ~$3,500 |
| **Dev Account** | Application developer sandboxes | ~$1,500 |
| **Shared Services Account**| Transit Gateway, GitHub runners, core ECR | ~$1,200 |
| **Security & Log Archive** | CloudTrail, Config, GuardDuty, S3 archiving | ~$1,300 |
| **AWS Support Plan** | AWS Enterprise Support Plan (10% flat rate) | ~$3,000 |
| **External integrations** | Okta, PagerDuty, GitHub Enterprise, LocalStack Pro | ~$3,000 |
| **Total All-Inclusive Budget**| | **~$31,500/mo** |

### 13.3 Cost Optimization & Savings Strategy
To keep actual spend below the budget ceiling, SRE implements:
- **Compute Savings Plans**: A 1-year Compute Savings Plan commitment of $1.50/hour covering baseline Karpenter nodes, Lambda, and Fargate runner execution, saving ~25% on compute costs.
- **Reserved Instances**: 1-year standard Reserved Instance commitments for predictable MSK brokers and Aurora primary database nodes, reducing data store expenses by up to 35%.
- **Idle Environment Downscaling**: Dev and Staging EKS workloads are automatically scaled to zero nodes outside working hours (7 PM to 7 AM local time) via cron schedulers.

---

## 14. Terraform Implementation & Testing Plan

### 14.1 Terraform Validation Strategy (Gap G11)
To ensure safety across 8 accounts, the pre-merge checks executed automatically inside **GitHub Actions CI runner pipelines** enforce:
1. **Formatting & Linting**: `terraform fmt` and `tflint`.
2. **Security Scan**: `checkov` checks for CIS benchmarks on every PR.
3. **Terratest Validation**: Integration tests verify module creation (e.g., spin up ephemeral VPC and tear down) before release.

---

## 15. Key Design Decisions & Trade-offs

### 15.1 Summary of Pros & Cons

#### Pros
- Exceptional multi-account boundaries reducing blast radius.
- Standardized secrets management and centralized egress routing lowering management cost.
- High DR capability with automated bi-annual verification schedules.

#### Cons
- High operational surface area for 3-5 SRE engineers (Istio, EKS upgrades, Thanos).
- Shield Advanced pricing ($3k/mo flat fee) represents a large chunk of the base network security budget.

---

## 16. Architectural Decision Records (ADRs)

### ADR-01: Secrets Management Engine
- **Status**: Approved.
- **Context**: Evaluated self-managed HashiCorp Vault on EKS vs. AWS Secrets Manager.
- **Decision**: AWS Secrets Manager selected due to lower operational overhead.
- **Consequences**: Avoids complex unseal token management and backup cycles, though it adds a per-secret API cost.

### ADR-02: Internet Egress Routing
- **Status**: Approved.
- **Context**: Evaluated local NAT Gateways in each account vs. a Central Egress VPC.
- **Decision**: Central Egress VPC selected to reduce NAT Gateway hourly charges.
- **Consequences**: Saves ~$300/mo per account, but introduces routing complexity and Transit Gateway data processing fees ($0.02/GB).

### ADR-03: Redshift & Analytical Workload Placement
- **Status**: Approved.
- **Context**: Evaluated hosting Redshift in the Prod account vs. a dedicated Data Analytics Account.
- **Decision**: Analytical clusters isolated to the Data Analytics Account.
- **Consequences**: Protects Prod compute and database performance; cross-account transfer utilizes restricted PrivateLink.

### ADR-04: Karpenter Auto-scaling Limits
- **Status**: Approved.
- **Context**: Runaway scaling risk on EKS worker nodes.
- **Decision**: Capped Karpenter limits strictly to 128 vCPUs and 512Gi memory.
- **Consequences**: Limits budget overruns. However, this could result in pod scheduling delays during unexpected massive traffic spikes. *Mitigation:* During planned high-traffic events (e.g., Black Friday), SRE will pre-warm node groups and temporarily raise Karpenter scaling quotas via Terraform.

### ADR-05: Container Registry Deployment Strategy
- **Status**: Approved.
- **Context**: Evaluated cross-account ECR replication vs. a centralized ECR registry.
- **Decision**: Centralized ECR registry in Shared Services with IAM policy pull grants and cross-region replication enabled to `us-west-2` for DR backup access.
- **Consequences**: Eliminates primary duplicate storage costs, but guarantees image availability in DR region during regional outage.

### ADR-06: Service Mesh Selection
- **Status**: Approved.
- **Context**: Evaluated Linkerd vs. Istio for EKS microservices.
- **Decision**: Istio chosen as the primary service mesh despite its operational complexity.
- **Consequences**: Istio's advanced canary traffic-splitting and granular mTLS authorization policies are required to meet strict PCI compliance guidelines and support zero-downtime microservice updates. SRE accepts the operational burden.
