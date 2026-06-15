# Company-Large: Enterprise Infrastructure Architecture & Global Design

> This document captures a large-scale, multi-national public organization's AWS enterprise infrastructure requirements, global active-active designs, multi-account structures, security guardrails, and platform engineering standards.

---

## 1. Company Profile & Assumptions

### 1.1 Business Context

| Assumption | Detail |
|---|---|
| **Company Size** | ~5,000+ employees, ~500+ engineers split into 40+ engineering squads |
| **Industry** | FinTech / Enterprise B2B SaaS (Global Payments & Analytics Platform) |
| **Stage** | Publicly traded company; high-growth, strict SLAs, global footprint |
| **Team Maturity** | Dedicated SRE Fleet (20+ engineers), Platform Engineering (15+), SecOps (10+), FinOps (3+), Compliance & Auditing (5+) |
| **Compliance Needs** | PCI-DSS Level 1, SOC 2 Type II, HIPAA, ISO 27001, FedRAMP Moderate, GDPR (EU residency), APRA (APAC region) |
| **Budget** | ~$380k-$500k / month on AWS (Multi-region, multi-account, global network) |
| **Regions** | Primary Hubs: `us-east-1` (US Primary), `eu-west-1` (EU Primary). DR/Active-Active Nodes: `us-west-2` (US Failover), `eu-central-1` (EU Failover). Edge: CloudFront POPs global with local caching. |
| **Deployment Frequency** | ~100+ deployments per day across all microservices; fully automated GitOps pipelines with progressive canary rollouts |

### 1.2 RACI Matrix & Ownership Boundaries

| Function | Platform Eng | SecOps | Core SRE | FinOps | Business Dev Squads |
|---|---|---|---|---|---|
| **Global Cloud WAN & Direct Connect** | Consulted (C) | Consulted (C) | **Accountable (A)** | Informed (I) | Informed (I) |
| **Service Control Policies (SCPs)** | Consulted (C) | **Accountable (A)** | Responsible (R) | Informed (I) | Informed (I) |
| **ArgoCD Hub & GitOps Fleet** | **Accountable (A)** | Consulted (C) | Responsible (R) | Informed (I) | Informed (I) |
| **KMS Key Policies & Secrets Rotation** | Responsible (R) | **Accountable (A)** | Responsible (R) | Informed (I) | Informed (I) |
| **Microservice Helm Charts & Code** | Informed (I) | Informed (I) | Informed (I) | Informed (I) | **Accountable (A)** |
| **Cluster Autoscaling & Karpenter Profiles** | **Accountable (A)** | Informed (I) | Responsible (R) | Consulted (C) | Informed (I) |
| **Cloud Cost Allocation & Reserved Instances** | Consulted (C) | Informed (I) | Consulted (C) | **Accountable (A)** | Responsible (R) |

*Legend: R = Responsible, A = Accountable, C = Consulted, I = Informed*

### 1.3 Out of Scope (What We Are Not Building & Why)

- **SaaS Application Core Logic**: We do not configure software repositories or runtime application code.
- **Physical Data Center Migration**: The physical lift-and-shift execution is managed by external systems integrators; this design covers the target AWS state.
- **Third-Party CRM / HR Systems Integration**: Workday, Salesforce, and client-facing service desk software integration are excluded.
- **Dedicated China Region (cn-north-1) Stack**: Due to the isolated Chinese legal framework, China-specific infrastructure is treated as a separate project with local partners.

---

## 2. Workload Deployment Families

The enterprise runs **5 core workload families**, distributed globally:

### 2.1 Workload Family A: High-Throughput Core Transactional Engines (EKS)
- **Description**: Core ledger, checkout services, payment routing, and customer APIs.
- **Compute**: EKS multi-cluster fleet running across 3 availability zones in US and EU. Node auto-provisioning handled by Karpenter, optimized for both compute (`c7i`) and memory (`r7i`) workloads.
- **Scaling**: Horizontal Pod Autoscalers (HPA) using custom Prometheus/Thanos metrics (e.g., HTTP request rate, queue depth) + Karpenter node autoscaling.
- **Ingress/Mesh**: AWS Application Load Balancer Ingress Controller → Istio Ambient Mesh (for sidecarless mTLS, layer-7 authorization, and telemetry).
- **Latency Optimization**: Low-latency payment write transactions are pinned to the primary database region (`us-east-1`). The secondary region is used for read-heavy operations, dynamic caching, and non-time-critical database writes via write-forwarding (tolerating the 100-200ms cross-region transit lag).
- **Data Dependency**: Aurora PostgreSQL Global Database (Active-Active with write-forwarding) + Redis Enterprise.

### 2.2 Workload Family B: Event-Driven Serverless Workflows
- **Description**: Notification engines, webhook dispatchers, post-transaction processing, audit trail generation.
- **Compute**: AWS Lambda (Node.js/Go) packaged as container images up to 10GB for fast cold starts, orchestrated via AWS Step Functions.
- **Messaging**: AWS EventBridge for global schema registry + Amazon MSK (Kafka) for event streaming across accounts.
- **Database**: Amazon DynamoDB Global Tables (multi-region replication, active-active).

### 2.3 Workload Family C: AI/ML Inference & Training Engine
- **Description**: Fraud detection models, custom LLM fine-tuning, real-time recommendation engines.
- **Compute**: SageMaker HyperPod clusters for model training + EKS Karpenter node groups utilizing GPU-optimized instances (`g5.xlarge`, `p4de.24xlarge`).
- **Orchestration**: Kubeflow Pipelines syncing with AWS Bedrock for foundation model API access.
- **Storage**: FSx for Lustre linked directly to S3 data lakes for ultra-fast training data throughput.

### 2.4 Workload Family D: Analytics & Enterprise Data Mesh
- **Description**: Financial reporting, auditing, customer behavior dashboards, data science sandboxes.
- **Storage**: AWS S3 Lakehouse (Apache Iceberg format) with AWS Lake Formation enforcing cell-level access control.
- **Compute**: Databricks on AWS for ETL processing + Redshift Serverless for ad-hoc SQL queries.
- **Data Ingest**: Amazon MSK Connect streaming raw transactional data into S3 via Kinesis Data Firehose.

### 2.5 Workload Family E: Hybrid Systems & Legacy Integrations
- **Description**: Core banking connections, legacy mainframe databases, partner VPN endpoints.
- **Compute**: Dedicated EC2 Bare Metal instances (`m7i-metal-24xl`) + AWS Outposts deployed in physical co-location facilities for local sub-millisecond execution.
- **Connectivity**: Redundant dual-link AWS Direct Connect (100 Gbps each) from separate carrier hotels. Additionally, a standby 10 Gbps IPSec VPN over the internet is configured to act as a fallback link in case both primary DX circuits fail.

---

## 3. Multi-Account & Organizational Structure

We employ **AWS Control Tower** to enforce standardization across a large multi-account hierarchy.

```
                           AWS Control Tower (Root Organization)
                                             │
      ┌──────────────────────┬───────────────┴───────────────┬──────────────────────┐
      ▼                      ▼                               ▼                      ▼
[Core Infrastructure]    [Security]                  [Business LOBs]            [Sandboxes]
  ├── Shared Services      ├── Security Tooling        ├── LOB Payments           ├── Dev Sandbox 1
  ├── Log Archive          ├── GuardDuty Delegated     │    ├── Dev Account       └── Dev Sandbox 2
  ├── Network Hub          ├── Incident Response       │    ├── Staging Account
  └── CI/CD Controllers    └── Audit & Archive         │    └── Prod Account
                                                       └── LOB Analytics
                                                            ├── Dev Account
                                                            └── Prod Account
```

### 3.1 Account Details & Organizational Units (OUs)

| OU Name | Account Name | Purpose | Tools Deployed |
|---|---|---|---|
| **Root** | Management | AWS Organizations billing, SCP management, Control Tower control plane. | Identity Center, Service Catalog |
| **Security** | Log Archive | Centralized collection of all AWS logs. Writable only by service roles. | Object Lock, Glacier lifecycle |
| **Security** | Security Tooling | Security administration, threat detection, vulnerability management. | GuardDuty, Security Hub, Inspector |
| **Core Infra** | Network Hub | Management of AWS Cloud WAN, Direct Connect, and Network Firewalls. | Cloud WAN Core, DX Gateway |
| **Core Infra** | Shared Services | Corporate tools, self-hosted VCS, container registries. | Harbor, Enterprise ECR, Private CAs |
| **Core Infra** | CI/CD Hub | Hub hosting central ArgoCD instances and orchestrators. | ArgoCD Hub, Runner Pools |
| **LOB Payments** | Dev / Staging / Prod | Dedicated accounts hosting the checkout and transactional workflows. | EKS, Aurora Global, Redis |
| **LOB Analytics**| Dev / Prod | Dedicated accounts hosting the Data Mesh Lakehouse. | Databricks, Redshift, Lake Formation |

### 3.2 Service Control Policies (SCPs)

The following SCPs are attached at the OU level to prevent configuration drift and restrict malicious activities:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDisablingSecurityServices",
      "Effect": "Deny",
      "Action": [
        "guardduty:Delete*",
        "guardduty:Archive*",
        "securityhub:Delete*",
        "securityhub:Disable*",
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "config:DeleteDeliveryChannel",
        "config:StopConfigurationRecorder"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyUnencryptedResources",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateVolume",
        "rds:CreateDBInstance",
        "s3:PutBucketEncryption"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "EnforceGDPRDataResidency",
      "Effect": "Deny",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::*-eu-data/*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "eu-west-1",
            "eu-central-1"
          ]
        }
      }
    },
    {
      "Sid": "RestrictRegions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1",
            "us-west-2",
            "eu-west-1",
            "eu-central-1"
          ]
        }
      }
    }
  ]
}
```

---

## 4. Network Architecture

A centralized hub-and-spoke networking model is deployed using **AWS Cloud WAN** for routing across multiple regions and accounts, with **AWS Network Firewall** ensuring deep packet inspection.

### 4.1 Global Network Flow

```
   On-Premises Data Center / Mainframe
                  │
        AWS Direct Connect (Redundant Dual 100G) + Backup VPN (10G)
                  │
        Direct Connect Gateway
                  │
          AWS Cloud WAN Core ──────── Peered Region Core (EU-West-1)
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
Network Hub VPC      Production VPC
  ├── Inspection       ├── Private App Subnets (EKS)
  └── Transit Firewalls└── Data Subnets (Aurora)
```

### 4.2 Network Firewall Segmentation

- **Egress VPC**: Outbound internet traffic from all workload VPCs is routed via Cloud WAN through a centralized Egress VPC containing AWS Network Firewall endpoints.
- **East-West Traffic**: Traffic between different Line of Business (LOB) VPCs is routed through the central Inspection VPC for stateful firewall rule verification.
- **NACL / Security Group Tiering**:
  - `Ingress ALB Security Group`: Restricts inbound traffic to CloudFront IP addresses only (managed prefix list).
  - `Private EKS Security Group`: Restricts inbound traffic to specific load balancer ports and permits node-to-node communication.
  - `Data Tier Security Group`: Restricts inbound traffic strictly to EKS worker node security groups.

---

## 5. Global Traffic Management & CDN

For a high-volume, multi-region API, Route 53 and CloudFront manage global edge routing.

### 5.1 Route 53 Active-Active Routing & Database Failover

```
                     Global User Client DNS Request
                                   │
                     Route 53 Geoproximity Resolver
                                   │
                 ┌─────────────────┴─────────────────┐
                 ▼                                   ▼
          US-East-1 Edge                      EU-West-1 Edge
                 │                                   │
       CloudFront CDN + WAF                CloudFront CDN + WAF
                 │                                   │
        Primary App (ALB)                   Standby App (ALB)
                 │                                   │
      ┌──────────┴──────────┐             ┌──────────┴──────────┐
      ▼                     ▼             ▼                     ▼
Aurora US Write      Aurora EU Read     Aurora EU Write      Aurora US Read
  (Active)             (Replica)          (Passive)            (Replica)
```

- **Database Write Forwarding**: To prevent cross-region network lag during transactions, the Aurora global cluster in the secondary region forwards write operations back to the primary database region (`us-east-1`) over the AWS global network transit backbone.
- **KMS Multi-Region Key Policy**: All storage components, databases, and backup snapshots utilize KMS Multi-Region keys (prefixed with `mrk-`). This ensures that during a failover event, keys are instantly usable in the DR target region without needing cross-region database re-encryption.
- **Failover SLA**: If `us-east-1` encounters a regional outage, Route 53 health checks trigger an automated failover. The secondary Aurora cluster in `eu-west-1` is promoted to primary writer in under 60 seconds, with DNS routing updated to point client write traffic directly to the European endpoint.

---

## 6. IAM & Security Governance

Identity and access control is automated to enforce least privilege access.

### 6.1 Enterprise Identity Federation

```
  Okta Identity Provider
          │
    SCIM Protocol
          │
          ▼
AWS IAM Identity Center
          │
  ┌───────┼───────┐
  ▼       ▼       ▼
SRE     SecOps  Devs
```

- **Federated Identities**: AWS IAM Identity Center integrates with corporate Okta directories using SCIM for user and group synchronization.
- **Ephemeral Access**: Production CLI access requires fetching temporary 1-hour credentials via Okta verification. Long-lived credentials (IAM Users) are blocked in production.
- **Permission Boundaries**: Application development teams can create local IAM roles for Lambdas/ECS but are restricted by a strict, pre-approved IAM Permission Boundary (`DeveloperPolicyBoundary`) that forbids modifying VPC configurations, altering routing, or accessing databases outside designated subnets.

---

## 7. Kubernetes Architecture (EKS) at Scale

Enterprise Kubernetes workloads run on multiple dedicated EKS clusters configured with sidecarless GitOps delivery models.

### 7.1 GitOps Infrastructure Fleet & HA Controller Deployment

```
        ArgoCD Hub Cluster (Primary: US-East-1 | Standby Replica: EU-West-1)
                                │
               GitOps Application Sync Engine
                                │
         ┌──────────────────────┼──────────────────────┐
         ▼                      ▼                      ▼
  EKS Cluster US-1       EKS Cluster US-2       EKS Cluster EU-1
   ├── Karpenter          ├── Karpenter          ├── Karpenter
   ├── Istio Ambient      ├── Istio Ambient      ├── Istio Ambient
   └── Prometheus Agent   └── Prometheus Agent   └── Prometheus Agent
```

- **ArgoCD High Availability**: The central ArgoCD configuration repository state is synchronized continuously to a secondary standby ArgoCD engine in `eu-west-1`. If the primary hub in `us-east-1` encounters a major outage, Route 53 DNS routes management traffic to the secondary instance, which takes over repository polling and cluster synchronization.
- **Istio Ambient Service Mesh**: We utilize Istio Ambient Mesh instead of sidecars. This reduces resource consumption by up to 45% and simplifies cluster upgrades by separating application logic from network transit.
- **Namespace-Level Isolation**: For multi-tenancy across 40+ squads, we deploy Kubernetes `ResourceQuotas` and explicit Cilium network policies restricting cross-namespace pod communication.
- **Karpenter Provisioning Guardrails**: NodePool configurations leverage a mix of On-Demand instances for Tier-1 core processing, and Spot instances for non-critical Tier-2/3 processing (saves up to ~$60k/month).
  ```yaml
  apiVersion: karpenter.sh/v1beta1
  kind: NodePool
  metadata:
    name: default-prod
  spec:
    template:
      spec:
        requirements:
          - key: karpenter.sh/capacity-type
            operator: In
            Values: ["on-demand", "spot"]
          - key: node.kubernetes.io/instance-type
            operator: In
            Values: ["m7i.2xlarge", "m7i.4xlarge", "r7i.2xlarge"]
        limits:
          Cpu: 2000
          Memory: 8000Gi
  ```
- **Policy Engine**: Kyverno enforces pod security standards (e.g., preventing privileged pods, requiring read-only root filesystems, and enforcing network policies).

### 7.2 EKS Lifecycle Upgrade Strategy
Upgrade procedures follow a strict phased schedule over a 6-week window:
```
Dev Clusters (Week 1-2) ──► Staging Clusters (Week 3-4) ──► Production Canary Nodes (Week 5) ──► Production 100% (Week 6)
```
New clusters are verified via GitOps traffic shifting using Argo Rollouts prior to draining the legacy node groups.

---

## 8. Data Platform, Backups & Secrets

### 8.1 Data Mesh Lakehouse
- **Lake Formation**: Manages granular column-level security across S3 Parquet tables.
- **S3 Object Lock**: Enabled in Compliance mode on Log Archive buckets with a 7-year retention period, preventing administrative deletion to ensure compliance with SEC Rule 17a-4.
- **Secrets Management**: AWS Secrets Manager encrypts and stores database passwords, rotating credentials automatically every 14 days using a custom AWS Lambda rotation helper.

---

## 9. CI/CD Pipelines & DevSecOps

Our CI/CD pipelines automate vulnerability scanning, policy checks, and secure deployment gates.

```
 Developer Commit
        │
 GitHub Actions CI
   ├── Checkov & TFlint IaC Scans
   ├── Snyk SAST Scan
   ├── Cosign Image Signing
   └── Push to AWS ECR
        │
   OIDC Authenticated Pull
        │
   ArgoCD Delivery
   └── Progressive Canary Rollout (Argo Rollouts)
```

- **Container Security**: ECR images are scanned with Amazon Inspector. Workloads containing critical vulnerabilities with CVSS scores > 8.0 are blocked from deployment.
- **Image Signing**: Ephemeral keys sign container images via Cosign. EKS Kyverno policies verify signatures at pod launch.

---

## 10. Observability & FinOps

Telemetry and cost optimization are monitored globally.

- **Thanos Metrics Stack**: Prometheus agents forward telemetry data to Thanos S3 buckets, enabling querying across all EKS clusters in a single dashboard.
- **Kubecost**: Deployed on all clusters to map resource costs back to specific development teams and namespaces, with FinOps generating monthly efficiency reports.

---

## 11. Disaster Recovery & Business Continuity

Our disaster recovery strategy minimizes downtime for critical workloads.

| Workload Tier | DR Strategy | Target RTO | Target RPO |
|---|---|---|---|
| **Tier 1 (Core Payments)** | Active-Active Multi-Region | < 60 seconds | Real-time |
| **Tier 2 (Internal Dashboards)** | Warm Standby (Pilot Light) | 1 hour | < 15 minutes |
| **Tier 3 (Batch Analytics)** | Backup & Restore | 24 hours | 1 hour |

- **Tabletop and Failover Exercises**: Weekly FIS chaos scenarios simulate node termination, while full-scale regional failover drills are scheduled quarterly under corporate operations supervision.

---

## 12. Cost Estimate (Monthly - All-Inclusive)

### 12.1 AWS Service Cost Allocation

| Service Component | Configuration Details | Monthly Cost |
|---|---|---|
| **Global EKS Compute** | 12 clusters, Karpenter-managed (On-Demand & Spot) | $95,000 |
| **Aurora Global Database** | 4 multi-region clusters, Multi-AZ | $85,000 |
| **AWS Cloud WAN & Transit Network** | Cloud WAN core, Nat Gateways + Data Processing | $50,000 |
| **VPC Interface Endpoints** | Redundant PrivateLink endpoints per VPC | $15,000 |
| **Inter-Region Data Transfer (IRDT)** | Global active-active data syncing | $20,000 |
| **Enterprise Security Suite** | Shield Advanced, Firewall Manager, Network Firewall | $35,000 |
| **Data Lakehouse Storage** | S3 (5 PB) + CloudFront Data Egress | $35,000 |
| **AWS Support Plan** | AWS Enterprise Support (10% flat rate) | $35,000 |
| **Third-Party SaaS** | Okta, Databricks, Datadog Enterprise, Snyk | $40,000 |
| **Total Monthly Spend** | | **$410,000** |

---

## 13. Architectural Decision Records (ADRs)

### ADR-01: Service Mesh (Istio Ambient Mesh)
- **Status**: Approved.
- **Context**: Standard Istio sidecars increase CPU and memory costs by up to 30%.
- **Decision**: Adopt Istio Ambient Mesh.
- **Consequences**: Separates traffic routing (Layer 4) from application pods. This reduces overhead, simplifies cluster updates, and lowers container memory footprints.

### ADR-02: Multi-Region Database Pattern
- **Status**: Approved.
- **Context**: Active-active write replication introduces consensus latency.
- **Decision**: Use Aurora Global Database with Write Forwarding for transaction engines and DynamoDB Global Tables for session data.
- **Consequences**: Standardizes multi-region availability while avoiding the conflict resolution complexity of master-master relational databases.

### ADR-03: GitOps Orchestration Tool
- **Status**: Approved.
- **Context**: Enterprise applications require centralized deployment controls.
- **Decision**: ArgoCD.
- **Consequences**: Code-defined cluster synchronization, Git history integration, and native support for progressive canary deployments using Argo Rollouts.

### ADR-04: Network Inspection Architecture
- **Status**: Approved.
- **Context**: Multi-tenant infrastructure requires centralized network inspection.
- **Decision**: Centralized AWS Network Firewall endpoints in an Inspection VPC.
- **Consequences**: Standardizes traffic filtering policies across all OUs, but introduces additional routing steps and inter-VPC traffic latency.

### ADR-05: Global Network Transport Routing
- **Status**: Approved.
- **Context**: Managing Transit Gateway peering meshes across multiple regions introduces administrative overhead.
- **Decision**: Use AWS Cloud WAN.
- **Consequences**: Simplifies global transit routing via code-defined core policies, but increases dependency on AWS global WAN availability.

### ADR-06: Identity Provider Integration
- **Status**: Approved.
- **Context**: User access management requires automated provisioning.
- **Decision**: Mapped AWS IAM Identity Center to Okta via SCIM.
- **Consequences**: Single Sign-On (SSO) authentication across all accounts with automated group mapping, removing the need for local IAM users.

### ADR-07: Container Image Verification
- **Status**: Approved.
- **Context**: Untrusted container images pose security risks.
- **Decision**: Sign images via Cosign and verify signatures during deployment using Kyverno.
- **Consequences**: Restricts execution of unsigned images, but requires managing public key distribution across clusters.

### ADR-08: Analytical Data Warehouse
- **Status**: Approved.
- **Context**: Relational databases are not optimized for petabyte-scale analytics.
- **Decision**: S3 Data Lakehouse using Apache Iceberg, queryable via Databricks and Redshift Serverless.
- **Consequences**: Separates storage from compute, reducing analytics costs and facilitating multi-engine queries.

### ADR-09: Telemetry Collection Standardization
- **Status**: Approved.
- **Context**: Proprietary monitoring agents cause vendor lock-in.
- **Decision**: OpenTelemetry (OTel) Collector agents.
- **Consequences**: Standardizes metric collection across workloads, simplifying data exports to systems like Thanos and Datadog.

### ADR-10: Multi-Cluster EKS Fleet Strategy
- **Status**: Approved.
- **Context**: Running all applications on a single Kubernetes cluster increases blast radius.
- **Decision**: Spoke cluster topology managed by a centralized ArgoCD hub.
- **Consequences**: Limits risk by isolating workloads, but increases cluster maintenance overhead (e.g., control plane upgrades).

### ADR-11: Hybrid Connectivity Network Redundancy
- **Status**: Approved.
- **Context**: Enterprise on-premises links require highly resilient path designs.
- **Decision**: Standardize on dual 100G Direct Connect circuits from diverse carriers with standby 10 Gbps Site-to-Site VPN as tertiary backup.
- **Consequences**: Protects against major carrier fiber cuts, but increases network leasing budgets.

### ADR-12: ArgoCD Deployment Model
- **Status**: Approved.
- **Context**: Single ArgoCD hub controller acts as a single point of failure (SPOF) for multi-cluster configuration sync.
- **Decision**: Deploy an Active-Standby controller configuration replicated dynamically between US-East-1 and EU-West-1.
- **Consequences**: Adds state synchronization overhead, but limits GitOps pipeline downtime to under 5 minutes during primary region failures.
