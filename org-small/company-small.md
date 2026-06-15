# Company-Small: Infrastructure Design & Assumptions

> This document captures a fictional small-sized company's AWS infrastructure requirements, assumptions, architecture decisions, and terraform implementation plan.

---

## 1. Company Profile & Assumptions

### 1.1 Business Context
| Assumption | Detail |
|---|---|
| **Company size** | ~20-50 employees, ~5-8 engineers (mix of backend, frontend, DevOps) |
| **Industry** | SaaS / Digital Product (e.g., Fintech, HealthTech, E-commerce) |
| **Stage** | Post-seed / Series A — growing fast, needs reliability but cost-conscious |
| **Team maturity** | No dedicated security team; 1-2 DevOps-minded engineers manage infra |
| **Compliance needs** | SOC 2 Type II in-progress; data encryption at-rest & in-transit required |
| **Budget** | ~$3k-$8k / month on AWS (compute + data + networking) |
| **Region** | Single primary region (`us-east-1`) with DR/multi-AZ planning |
| **Deployment frequency** | Multiple deploys per week; CI/CD via GitHub Actions |

### 1.2 Workload Assumptions
| Assumption | Detail |
|---|---|
| **Application types** | 3 distinct workloads — see below |
| **Traffic profile** | Moderate: 5k-50k daily active users; spiky (business hours) |
| **Data sensitivity** | PII/PHI in database; all APIs require authentication |
| **Tech stack** | Node.js / Python backends, React frontend, PostgreSQL, Redis |
| **Containerization** | Moving toward containers; some legacy VMs remain |
| **Monitoring** | CloudWatch + third-party (Datadog/Grafana) |

---

## 2. Workload Deployment Types

The company runs **3 distinct workload types**, each with different infrastructure needs:

### 2.1 Workload A: Legacy Monolith on EC2 (VM)
| Aspect | Detail |
|---|---|
| **What** | Legacy Node.js/Python monolith (admin panel, reporting engine) |
| **Why VM** | Not yet containerized; heavy filesystem dependency, long-running batch jobs |
| **Deployment** | Single EC2 + standby in another AZ (pilot light DR) |
| **Size** | `t3.medium` (active) + `t3.small` (standby, stopped) |
| **AMI** | Amazon Linux 2023 |
| **Storage** | 2x 50GB gp3 (root + data) + EFS for shared files |
| **Admin access** | SSM Session Manager (no bastion, no SSH keys on instances) |

### 2.2 Workload B: Auto-Scaled Service on EC2 (VM Set / ASG)
| Aspect | Detail |
|---|---|
| **What** | Stateless API backend (customer-facing REST/gRPC API) |
| **Why VM Set** | Needs predictable performance, GPU optional future; not yet on K8s |
| **Deployment** | Auto Scaling Group across 2 AZs, min=2, max=6 |
| **Size** | `t3.large` instances |
| **AMI** | Amazon Linux 2023 + custom baked AMI (Packer) |
| **Scaling** | CPU-based (target 60%) + schedule for peak hours |
| **Load balancer** | ALB (internet-facing) with WAF |
| **Admin access** | SSM Session Manager (no SSH key pairs distributed) |

### 2.3 Workload C: Microservices on EKS (Kubernetes)
| Aspect | Detail |
|---|---|
| **What** | Containerized microservices (user service, payment, notifications, etc.) |
| **Why EKS** | Team wants K8s for velocity; 6-10 microservices already containerized |
| **Cluster size** | 3x `t3.medium` node group (on-demand) + 2x `t3.medium` spot (burst) |
| **Node group** | Managed node groups, 2 AZs |
| **Namespace strategy** | `prod`, `staging`, `monitoring` |
| **Ingress** | ALB Ingress Controller + NGINX Ingress |
| **Service mesh** | None yet (future: Istio or Linkerd) |
| **Secrets delivery** | External Secrets Operator syncing from AWS Secrets Manager |
| **Admin access** | AWS SSO → EKS `aws-auth` ConfigMap (no static kubeconfig) |

---

## 3. Network Architecture

### 3.1 VPC Design
```
10.0.0.0/16
├── 10.0.1.0/24  ── Public Subnet  (az-a)  ← NAT Gateway + ALB + Bastion (disabled)
├── 10.0.2.0/24  ── Public Subnet  (az-b)  ← NAT Gateway + ALB + Bastion (disabled)
├── 10.0.11.0/24 ── Private Subnet (az-a)  ← EC2, ASG, EKS nodes
├── 10.0.12.0/24 ── Private Subnet (az-b)  ← EC2, ASG, EKS nodes
├── 10.0.21.0/24 ── Data Subnet   (az-a)  ← RDS, ElastiCache, EFS
└── 10.0.22.0/24 ── Data Subnet   (az-b)  ← RDS, ElastiCache, EFS
```

> The public subnets retain their CIDR allocation but **no bastion host is deployed**. SSM Session Manager handles all instance access.

### 3.2 Connectivity & Least-Access Principles
| Component | Access Rule | Rationale |
|---|---|---|
| **Public subnets** | Only ALBs and NAT Gateways | No bastion; SSM VPC Endpoint handles admin access |
| **Private subnets** | Ingress only from ALB SG / NAT GW | Apps cannot be reached from internet |
| **Data subnets** | Ingress only from App SGs | Databases have no public route |
| **Instance access** | SSM Session Manager (no SSH ports open) | IAM-audited, no key management, no public endpoints |
| **VPC Flow Logs** | Enabled (all subnets) | Audit & security analysis |
| **S3 VPC Endpoint** | Gateway endpoint | Private access to S3 (no NAT cost) |
| **EKS API endpoint** | Private only (no public endpoint) | K8s control plane not exposed |
| **SSM VPC Endpoints** | Interface endpoints for SSM + EC2Messages | Required for SSM Session Manager in private subnets |

### 3.3 SSM Session Manager Architecture
- **No bastion host** — eliminated entirely (reduces cost, attack surface, maintenance)
- **SSM VPC Endpoints** deployed in private subnets (3 interface endpoints: `ssm`, `ssmmessages`, `ec2messages`)
- **IAM policy** enforces SSM `StartSession` on specific instance ARNs + tags
- **CloudTrail** logs every SSM session (who, when, which instance, commands)
- **Session logging** to CloudWatch Logs or S3 for audit trail
- **No SSH ports** (port 22) open in any security group

### 3.4 Network Hardening
- Default NACLs replaced with explicit allow rules per subnet tier
- Security groups follow "deny all, allow specific" — no `0.0.0.0/0` except ALB
- **No direct internet for private subnets** — egress via NAT Gateway (HA, 1 per AZ)
- VPC Peering / Transit Gateway ready for future office/DR VPC

---

## 4. DNS & SSL Automation

A gap identified during review — the company needs automated DNS and certificate management.

| Component | Implementation |
|---|---|
| **Domain** | `company-small.io` managed in Route 53 (public hosted zone) |
| **TLS certificates** | ACM certs auto-issued and renewed via DNS validation |
| **DNS records** | Route 53 alias records for ALBs (`api.company-small.io`, `app.company-small.io`) |
| **Internal DNS** | Route 53 private hosted zone for internal service discovery (`*.internal.company-small.io`) |
| **Automation** | Terraform manages all Route 53 records and ACM certificates as part of the `networking` module |
| **Validation** | ACM DNS validation records created automatically via `aws_route53_record` |

---

## 5. IAM Architecture

### 5.1 IAM Principles
| Principle | Implementation |
|---|---|
| **Least privilege** | Every role/permission scoped to specific resource ARNs |
| **No long-lived keys** | All workloads use IAM Instance/Service Roles |
| **Human access** | SSO (IAM Identity Center) + OIDC from GitHub |
| **Machine access** | GitHub Actions OIDC (no static creds) |
| **Secrets rotation** | Secrets Manager with auto-rotation for RDS |
| **SSM access** | SSM StartSession allowed only to specific instance ARNs + resource tags |

### 5.2 IAM Roles & Policies
| Role | Trust Entity | Managed Policies |
|---|---|---|
| `ec2-legacy-role` | EC2 Service | `AmazonSSMManagedInstanceCore`, custom inline: `S3ReadOnly`, `CWAgent`, `SecretsManagerRead` |
| `asg-api-role` | EC2 Service | Same as `ec2-legacy-role` + `ECRReadOnly` |
| `eks-node-role` | EC2 Service | `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonSSMManagedInstanceCore` |
| `eks-cluster-role` | EKS Service | `AmazonEKSClusterPolicy` |
| `github-actions-role` | GitHub OIDC | Custom: `ECR:*`, `ECS:*`, `S3:*` (scoped), `IAM:PassRole`, `SSM:StartSession` |
| `backup-role` | AWS Backup | `AWSBackupServiceRolePolicy`, custom for S3/RDS |
| `sre-readonly-role` | AWS SSO | `ReadOnlyAccess` + `AmazonS3ReadOnlyAccess` + `SSM:DescribeSessions` for auditing |

### 5.3 SSM Session Manager IAM
- Dedicated permission boundary for SSM access
- `ssm:StartSession` scoped to instances with tag `Environment=prod` + `SSMManaged=true`
- `ssm:TerminateSession` allowed for own sessions only
- CloudTrail + CloudWatch logging enabled on all SSM sessions
- No SSH keys stored anywhere

### 5.4 Service Control Policy (SCP) — if Organizations
- Deny leaving Organizations
- Deny disabling CloudTrail / Config
- Deny creating access keys for root user
- Deny modifying VPC Flow Logs
- Deny public RDS / S3 bucket access

---

## 6. Secrets Delivery Pipeline

Another gap from initial design — how secrets get to workloads securely.

| Workload | Mechanism | Details |
|---|---|---|
| **Workload A (EC2 monolith)** | `aws ssm get-parameters` on boot via user-data script; instance role scoped to specific secret ARNs | Secrets cached to encrypted EBS volume; auto-refresh via cron/systemd timer |
| **Workload B (ASG API)** | Same as Workload A + env vars injected at application startup from Secrets Manager | No secrets in AMI or user-data logs |
| **Workload C (EKS pods)** | External Secrets Operator (ESO) running in-cluster, syncing Secrets Manager → K8s Secrets | Native K8s secret objects auto-refreshed when secrets rotate |
| **CI/CD (GitHub Actions)** | GitHub OIDC role assumes IAM role; secrets fetched at deploy time via AWS SDK | No secrets in GitHub Secrets UI; fetched fresh per pipeline run |
| **Rotation** | RDS password auto-rotation via Secrets Manager Lambda | Rotated every 30 days; zero-downtime via rotation function |

---

## 7. Data Layer

| Service | Configuration | Access |
|---|---|---|
| **RDS PostgreSQL** | `db.t3.medium`, Multi-AZ, encrypted, automated backups (35d) | Data subnet, SG from App tiers |
| **ElastiCache Redis** | `cache.t3.small`, cluster mode disabled, encrypted in-transit | Data subnet, SG from App tiers |
| **EFS** | General Purpose, burst mode, encrypted | Private subnet mount targets (both AZs) |
| **S3** | 3 buckets: `app-logs`, `app-backups`, `app-assets` | VPC Endpoint + bucket policies limiting to roles |
| **Secrets Manager** | RDS creds, API keys, third-party tokens | All access via IAM roles; no hardcoded secrets anywhere |

### 7.1 Environment Downscaling (Non-Prod)
To prevent the AWS bill from tripling when copying this stack to dev/staging environments:

| Service | Production | Staging | Dev |
|---|---|---|---|
| **RDS** | Multi-AZ, `db.t3.medium` | Single-AZ, `db.t3.small` | Single-AZ, `db.t3.micro` |
| **NAT Gateway** | 2 (one per AZ) | 1 | 1 (or NAT instance at $15/mo) |
| **EC2 (legacy)** | Active + standby | Single `t3.small` | Single `t3.nano` |
| **ASG** | min=2, max=6 | min=1, max=2 | min=1, max=1 |
| **EKS** | 3 on-demand + 2 spot | 2 `t3.small` managed | 2 `t3.small` managed (or Fargate profiles) |
| **Backups** | 35d retention | 14d retention | 7d retention |

> Estimated non-prod cost: **~$400/mo** (staging) + **~$250/mo** (dev) = total infra bill **~$1,600/mo** across all environments.

---

## 8. Security & Compliance

| Layer | Implementation |
|---|---|
| **Encryption at rest** | RDS/ElastiCache/EFS/EBS — all encrypted with AWS KMS (customer-managed key) |
| **Encryption in transit** | ALB terminates TLS (ACM cert), internal traffic uses mTLS (future) |
| **WAF** | Attached to public ALB: rate limiting, SQLi/XSS rules, IP blocklist |
| **Backup** | AWS Backup with cross-region copy for critical data |
| **Logging** | CloudTrail (multi-region), VPC Flow Logs, CloudWatch Logs (all apps), SSM session logs |
| **Alerting** | CloudWatch Alarms → SNS → Slack/PagerDuty |
| **Patch management** | Systems Manager Patch Manager (monthly maintenance window) |
| **Vulnerability scanning** | Amazon Inspector (EC2 + ECR) |
| **Secret scanning** | GitLeaks or truffleHog in CI/CD pipeline |

---

## 9. Design Benefits

| Benefit | Explanation |
|---|---|
| **Layered security** | 3-tier subnet isolation (public → private → data) ensures defense-in-depth |
| **Least privilege by design** | Every EC2/container/CI pipeline has a scoped IAM role; no shared credentials |
| **No bastion host** | SSM Session Manager eliminates public SSH endpoints, key management, and bastion cost (~$15-30/mo saved) |
| **Audit-ready admin access** | SSM sessions are IAM-authenticated, CloudTrail-logged, and can be recorded to CloudWatch |
| **Cost efficiency** | Spot instances for EKS burst, right-sized instances, tiered non-prod downscaling |
| **Operational simplicity** | Managed services (RDS, ElastiCache, EKS) reduce undifferentiated heavy lifting |
| **Future-proof** | EKS ready for full container migration; VPC CIDR allows expansion |
| **SOC 2 alignment** | CloudTrail + VPC Flow Logs + SSM audit logs + KMS encryption meet evidence requirements |
| **Scalability** | ASG + EKS HPA handle traffic spikes; Multi-AZ ensures availability |
| **Zero-trust infrastructure** | No public endpoints for databases or app instances; all traffic via ALB/NAT/SSM |
| **Reduced state blast radius** | 3 state files (networking, data-stores, apps) prevent correlated failures |

---

## 10. Design Limitations & Risks

| Limitation | Risk / Impact | Mitigation |
|---|---|---|
| **Single-region** | Regional outage takes down everything | Multi-AZ mitigates AZ failure; DR plan via RDS cross-region backups |
| **NAT Gateway cost** | ~$32/mo per NAT GW (x2 AZs = $64/mo) | Consider NAT instance for non-prod; single NAT GW for dev/staging |
| **No Transit Gateway** | Adding VPCs for CI/CD, DR, or Office requires VPC Peering (spaghetti) | Accept for now; introduce TGW when >3 VPCs |
| **EKS control plane** | $73/mo fixed cost regardless of usage | Worth it for team velocity; evaluate if usage drops |
| **EKS upgrade overhead** | Upgrades every 4-6 months often break API versions, requiring regression testing | Use managed node groups; test upgrades in staging first |
| **No service mesh** | mTLS and observability per-service (manual effort) | Introduce Istio/Linkerd in next 6 months |
| **No CDN** | Global users experience latency | Add CloudFront for static assets (low effort) |
| **No dedicated security team** | Misconfigurations could go unnoticed | Automated scanning (Checkov, tfsec) in CI/CD pipeline |
| **Operational burnout risk** | 1-2 DevOps managing EC2 + ASG + EKS + networking + data stores = high cognitive load | Prioritize automation; consider consolidating compute under ECS Fargate in next phase |
| **State file separation complexity** | 3 state files require coordinated apply ordering (networking → data → apps) | Use `terraform_remote_state` data sources and scripted apply pipeline |
| **SSM VPC Endpoint cost** | 3 interface endpoints per VPC (~$7.30/mo each = ~$22/mo per env) | Acceptable trade-off vs. bastion host cost + maintenance |
| **vCPU limits** | Accounts have soft limits (e.g., 5-20 vCPUs) | Request limit increases before launch; use t3 burstable for dev |
| **Secrets refresh delay** | ESO polls Secrets Manager on interval; rotated secrets may take seconds to propagate to pods | Set ESO refresh interval to 60s; application-level retry for stale secrets |

---

## 11. Cost Estimate (Monthly)

### 11.1 Production
| Service | Estimated Cost |
|---|---|
| VPC + NAT Gateways (2) | ~$68 |
| EC2 (Legacy + ASG + SSM endpoints) | ~$190 |
| EKS Control Plane | ~$73 |
| EKS Worker Nodes (5x t3.medium) | ~$250 |
| RDS PostgreSQL (Multi-AZ) | ~$200 |
| ElastiCache Redis | ~$30 |
| EFS (storage + throughput) | ~$30 |
| ALB (2x) | ~$45 |
| NAT Gateway data processing | ~$20 |
| S3 + Data Transfer | ~$20 |
| CloudWatch + Logs | ~$30 |
| KMS keys | ~$10 |
| SSM VPC Endpoints (3) | ~$22 |
| Route 53 + ACM | ~$5 |
| **Total Production** | **~$993/mo** |

### 11.2 All Environments
| Environment | Monthly Cost |
|---|---|
| Production | ~$993 |
| Staging (downscaled) | ~$400 |
| Dev (downscaled) | ~$250 |
| **Total** | **~$1,643/mo** |

> Note: Excludes support plan, SSO, Inspector, and backup storage overhead. Non-prod downscaling saves ~$1,000/mo vs. full copy.

---

## 12. Terraform Implementation Plan

### 12.1 Module Structure
```
terraform-ws/
├── environments/
│   ├── dev/
│   │   ├── networking.tf
│   │   ├── data-stores.tf
│   │   └── apps.tf
│   ├── staging/
│   │   ├── networking.tf
│   │   ├── data-stores.tf
│   │   └── apps.tf
│   └── prod/
│       ├── networking.tf
│       ├── data-stores.tf
│       └── apps.tf
├── modules/
│   ├── networking/          # VPC, subnets, NAT, flow logs, SSM endpoints, Route53
│   ├── security/            # SGs, NACLs, KMS, ACM
│   ├── iam/                 # Roles, policies, OIDC provider
│   ├── ec2-legacy/          # Workload A (monolith + standby)
│   ├── asg-api/             # Workload B (ALB + ASG + launch template)
│   ├── eks/                 # Workload C (cluster + node groups + ESO)
│   ├── rds/                 # PostgreSQL (Multi-AZ toggle)
│   ├── redis/               # ElastiCache
│   ├── s3/                  # Buckets + policies + VPC endpoint
│   ├── secrets/             # Secrets Manager + auto-rotation Lambda
│   ├── monitoring/          # CloudWatch, alarms, dashboards
│   └── ssm/                 # SSM documents + session manager config
├── backend.tf               # S3 + DynamoDB backend config (per env)
├── providers.tf             # AWS provider + aliases
├── variables.tf             # Global variables
└── outputs.tf               # Global outputs
```

### 12.2 State File Decomposition (3 Tiers)
To minimize blast radius and allow parallel applies:

| State File | Contains | Apply Order |
|---|---|---|
| `networking.tfstate` | VPC, subnets, NAT, route tables, flow logs, SSM endpoints, Route53, ACM | 1st |
| `data-stores.tfstate` | RDS, ElastiCache, EFS, S3, Secrets Manager | 2nd (after networking) |
| `apps.tfstate` | IAM roles, EC2, ASG, EKS, monitoring, SSM docs | 3rd (after data) |

**State references:**
- `data-stores` reads VPC/subnet IDs from `networking` via `terraform_remote_state`
- `apps` reads both networking outputs and data store endpoints via `terraform_remote_state`
- DynamoDB state lock prevents concurrent writes within a tier

### 12.3 Module Dependency Flow
```
providers.tf
    └── [1] networking (VPC → Subnets → NAT → Route Tables → Flow Logs → SSM Endpoints → Route53 → ACM)
        └── [2] data-stores (RDS, Redis, EFS, S3, Secrets)
            └── [3] apps
                ├── iam (Roles → Policies → OIDC)
                ├── ec2-legacy (depends on: networking, data-stores, iam)
                ├── asg-api (depends on: networking, data-stores, iam)
                ├── eks (depends on: networking, data-stores, iam)
                ├── monitoring (depends on: all apps)
                └── ssm (depends on: all apps)
```

### 12.4 Key Module Variables (Environment-Specific)
| Variable | Dev | Staging | Prod |
|---|---|---|---|
| `rds_multi_az` | false | false | true |
| `rds_instance_class` | `db.t3.micro` | `db.t3.small` | `db.t3.medium` |
| `nat_gw_count` | 1 | 1 | 2 |
| `asg_min_size` | 1 | 1 | 2 |
| `asg_max_size` | 1 | 2 | 6 |
| `eks_node_desired` | 1 | 2 | 3 |
| `backup_retention_days` | 7 | 14 | 35 |

### 12.5 CI/CD Integration
- GitHub Actions OIDC role assumed per environment
- `terraform plan` on PR, `terraform apply` on merge to `main`
- `terraform validate` + `checkov` scanning in CI
- `tfsec` policy-as-code with gates (no critical/high failures)
- State file lock via DynamoDB prevents concurrent applies

---

## 13. Version 2: Architecture Review & Critique

Following an in-depth review of the initial design (Version 1), this section captures the full critique. **The core compute architecture (EC2 + ASG + EKS) was retained** per the original requirement, but the actionable non-compute recommendations (SSM, state decomposition, DNS/SSL, secrets delivery, env downscaling) have been integrated into the main design above.

### 13.1 Pros (V2 Assessment)
- **Strong Perimeter Security:** The 3-tier VPC design successfully isolates data layers from the internet.
- **Modern IAM Practices:** Using AWS SSO (IAM Identity Center) and GitHub OIDC role assumption eliminates long-lived credentials.
- **Compliance Preparedness:** S3 gateway endpoints, VPC Flow Logs, multi-region CloudTrail, and KMS CMKs position the company well for SOC 2 Type II audit readiness.
- **SSM Adoption:** Replacing the bastion host with SSM Session Manager improves security posture and operational hygiene.

### 13.2 Cons (V2 Assessment)
- **High Compute Complexity:** Managing a monolith on EC2, an ASG with custom AMIs, *and* an EKS cluster imposes excessive cognitive load on a tiny 1-2 DevOps team.
- **Kubernetes Upgrade Overhead:** EKS requires active maintenance. Upgrades every 4-6 months frequently introduce breaking changes in API versions, requiring continuous regression testing.
- **State File Complexity:** While separated into 3 tiers, the orchestration of apply ordering and `terraform_remote_state` data sources adds pipeline complexity.

### 13.3 Gaps (Now Addressed)
- **DNS & SSL Automation:** ✅ Integrated into Section 4 (Route 53 + ACM via Terraform)
- **Secrets Delivery Pipeline:** ✅ Integrated into Section 6 (ESO for EKS, SSM Parameter Store for EC2)
- **Environment Parity Costs:** ✅ Integrated into Section 7.1 (downscaling tables for non-prod)
- **SSM Endpoint Cost:** ✅ Called out in Section 10 & 11

### 13.4 Residual Risks
- **Operational Burnout:** The small team (1-2 DevOps) will spend significant time on cluster upgrades, AMI baking, and ingress rule maintenance. This is the #1 risk of the retained compute architecture.
- **State file Cross-References:** `terraform_remote_state` creates implicit dependencies across the 3 state files. A `destroy` or `import` operation in one tier can break references in another.
- **Secrets Propagation Delay:** ESO polling interval means a rotated database credential may take up to 60 seconds to reach all pods, potentially causing transient auth failures.

### 13.5 Future Recommendations
1. **Medium-term (6-12 months):** Evaluate consolidating Workload A (EC2 monolith) and Workload B (ASG API) onto ECS Fargate, keeping only Workload C (microservices) on EKS. This reduces EC2 management and AMI overhead.
2. **Long-term (12+ months):** Evaluate moving entirely to EKS or entirely to ECS Fargate, depending on team size and K8s expertise growth.
3. **Always:** Replace `terraform_remote_state` with a shared data layer (e.g., SSM Parameter Store or Consul) for cross-stack references to break the tight coupling.

---

## 14. Next Steps

1. ✅ **Phase 0** — Write this document (done)
2. 🔲 **Phase 1** — Create Terraform modules: `networking` → `security` → `iam`
3. 🔲 **Phase 2** — Create Terraform modules: `ec2-legacy`, `asg-api`, `eks`
4. 🔲 **Phase 3** — Create Terraform modules: `rds`, `redis`, `s3`, `ssm`, `secrets`
5. 🔲 **Phase 4** — Monitoring, backup, logging modules
6. 🔲 **Phase 5** — Environment root modules with 3-tier state separation (`dev`, `staging`, `prod`)
7. 🔲 **Phase 6** — CI/CD pipeline (GitHub Actions) + policy-as-code (Checkov/tfsec)

---

## 15. Independent Analysis & Recommendations

### 15.1 Executive Summary

The plan is **well-architected for a security-conscious, SOC 2-bound SaaS company** but **over-engineered for the team size**. The core tension: the infrastructure design assumes a DevOps maturity level (K8s, multi-state Terraform, custom AMIs) that outpaces the reality of a 1-2 person infra team. The primary recommendation is to **reduce compute surface area** before operational fatigue sets in.

### 15.2 Pros

| # | Pro | Why It Matters |
|---|---|---|
| 1 | **3-tier subnet isolation** (public → private → data) | Defense-in-depth; no database or app instance has a public route |
| 2 | **No bastion host / SSH-free** | Eliminates key management, public attack surface, and ~$15-30/mo bastion cost |
| 3 | **SSM Session Manager with full audit** | Every admin session is IAM-authenticated, CloudTrail-logged, and recordable — SOC 2 evidence without extra tooling |
| 4 | **GitHub OIDC (no static creds)** | Zero long-lived AWS keys in CI/CD; role assumption per pipeline run |
| 5 | **Environment downscaling tables** | Realistic dev/staging sizing saves ~$1,000/mo vs. full copies |
| 6 | **Secrets delivery pipeline per workload** | SSM Parameter Store for EC2, ESO for K8s — workload-appropriate rather than one-size-fits-all |
| 7 | **Cost estimate transparency** | ~$1,643/mo total is realistic and within the $3k-8k budget |
| 8 | **State decomposition into 3 tiers** | Limits blast radius; parallel applies possible for networking vs. data vs. apps |
| 9 | **Checkov/tfsec in CI/CD** | Catches misconfigurations before apply — critical given no dedicated security team |
| 10 | **KMS CMK everywhere** | Customer-managed keys for all encrypted resources; meets SOC 2 / compliance requirements |

### 15.3 Cons

| # | Con | Impact |
|---|---|---|
| 1 | **3 compute platforms (EC2 + ASG + EKS)** for a 1-2 person team | Massive cognitive load; each platform has distinct upgrade, patching, and troubleshooting procedures |
| 2 | **EKS for 6-10 microservices on a small team** | K8s is a full-time job. The $73/mo control plane is the smallest cost — the real cost is engineer time spent on cluster upgrades, node group management, and debugging |
| 3 | **3-state-file orchestration complexity** | `terraform_remote_state` creates fragile cross-references; a destroy/import in one state can break others; apply ordering must be scripted |
| 4 | **No CDN** | Global users experience latency; CloudFront would be low-effort, high-value |
| 5 | **No ephemeral / preview environments** | No per-PR infrastructure for testing changes before merge |
| 6 | **No explicit DR runbook or RTO/RPO** | Cross-region backups exist but no documented recovery procedure |
| 7 | **No AWS Budgets or cost anomaly detection** | Cost overruns would be detected reactively (when the bill arrives) |
| 8 | **No CI/CD runner infrastructure** | GitHub Actions runners live... where? No self-hosted runner pool is defined; public runners may have IP restrictions |
| 9 | **NAT Gateway cost per AZ** | $68/mo for NAT GWs + $20/mo data processing = ~$88/mo just to let private subnets reach the internet |
| 10 | **Service mesh deferred** | Without mTLS, internal traffic between microservices on EKS is unauthenticated |

### 15.4 Risks (Prioritized)

| # | Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|---|
| 1 | **Operational burnout / bus factor** — 1-2 DevOps managing 3 compute platforms, networking, data stores, CI/CD, and security scanning | High | Critical | Consolidate compute platforms; document everything; cross-train with engineers |
| 2 | **EKS upgrade breakage** — Every 4-6 months, API version drift breaks workloads; requires regression testing | High | High | Consider ECS Fargate instead; if staying on EKS, invest in staging-first upgrade pipeline with automated canary testing |
| 3 | **State file reference brittleness** — `terraform_remote_state` in 3 tiers; a `terraform destroy` in networking breaks data-stores and apps | Medium | High | Migrate to Terraform Cloud / TFC or use SSM Parameter Store as a shared data layer for cross-stack references |
| 4 | **Single-region outage** — No active DR despite SOC 2 in-progress | Medium | High | Define RTO/RPO; document manual recovery from cross-region backups; test failover quarterly |
| 5 | **Secrets propagation delay** — ESO 60s poll interval means rotated creds cause transient auth failures | Medium | Medium | Reduce ESO poll interval; add application-level retry with backoff |
| 6 | **vCPU service limits** — Default AWS account limits may block node group scaling | Low | High | Request limit increases during Phase 1; use t3 burstable for dev to stay within limits |
| 7 | **Ghost costs** — No budget alerts; NAT GW data processing, data transfer, and CloudWatch log ingestion can silently inflate bills | Medium | Medium | Set up AWS Budgets with alerting at 80%/100%; enable Cost Explorer; tag all resources |
| 8 | **Talent dependency** — Custom AMI baking (Packer), EKS management, and SSM automation knowledge is specialized and hard to replace | Medium | High | Use AWS-provided AMIs where possible; standardize on SSM documents; document all manual procedures |
| 9 | **IP Address Exhaustion in Private Subnets** — EKS VPC CNI allocates dedicated IPs for pods; `/24` subnets (251 IPs) will exhaust quickly with multiple namespaces/pods | High | High | Increase private subnets to `/22` or utilize prefix delegation in VPC CNI configuration |
| 10 | **EFS Monolith Performance Bottlenecks** — Default EFS bursting mode can severely throttle filesystems under heavy file operations, causing monolith stalls | Medium | High | Enforce "Elastic Throughput" mode in EFS module configurations |

### 15.5 Strategic Suggestions (Prioritized)

| Priority | Suggestion | Effort | Impact | Rationale |
|---|---|---|---|---|
| **P0** | **Consolidate Workload A + B under a single ASG or ECS Fargate** | Medium | High | Eliminates one compute platform and AMI baking. EC2 monolith (Workload A) can run on the same ASG as Workload B with a separate launch template. Even better: move both to ECS Fargate to eliminate EC2 management entirely — this alone cuts operational load by ~40% |
| **P0** | **Replace EKS with ECS Fargate** | Medium | High | For 6-10 microservices and a 1-2 person DevOps team, ECS Fargate provides the same container orchestration benefits without: master upgrades, node group management, CNI plugins, or `aws-auth` ConfigMap maintenance. Cost is comparable or lower. Only keep EKS if the team has deep K8s expertise or plans to hire dedicated K8s engineers |
| **P1** | **Add CloudFront CDN** | Low | Medium | 1-2 days of work; reduces global latency for static assets; adds DDoS protection (AWS Shield Standard); costs ~$10-20/mo for moderate traffic |
| **P1** | **Implement AWS Budgets + Cost Anomaly Detection** | Low | Medium | Prevents bill shock; ~1 hour setup; tag enforcement via SCP ensures cost allocation |
| **P1** | **Add ephemeral preview environments** | Medium | Medium | Per-PR Terraform apply in isolated namespaces/accounts; enables testing before merge; can use Terraform Workspaces or separate root modules |
| **P2** | **Reduce from 3 state files to 2** | Low | Low | Merge `data-stores` and `apps` into a single state file; keep `networking` separate (it changes rarely). Simpler orchestration, fewer remote state references |
| **P2** | **Document DR runbook with RTO/RPO** | Medium | High | Define: RTO = 4 hours, RPO = 1 hour. Document steps to promote cross-region backup RDS, redeploy EKS from backup, and update Route 53 DNS |
| **P2** | **Replace `terraform_remote_state` with SSM Parameter Store for cross-stack references** | Medium | Medium | Breaks the tight coupling between state files; each module writes outputs to SSM Parameter Store; consumers read from SSM instead of remote state |
| **P3** | **Evaluate Karpenter for EKS (if staying on K8s)** | Medium | Medium | Reduces node group management overhead; auto-selects instance types; but adds another tool to learn |
| **P3** | **Add self-hosted GitHub Actions runners on EC2/ECS** | Medium | Low | Prevents IP-based restrictions on API calls; but adds maintenance — balance against using larger public runners |
| **P1** | **Enforce CloudWatch Log Retention & Glacier Archival** | Low | High | Set a 30-day retention policy on all CloudWatch log groups in Terraform to avoid ghost costs, and forward archives to S3 Glacier with Object Lock (compliance mode) for audit logs |
| **P1** | **Deploy AWS Backup Vault Lock** | Low | High | Protect backups against ransomware and accidental deletions by enabling AWS Backup Vault Lock in compliance mode |
| **P2** | **Deploy ECS Task Runner for Database Migrations** | Medium | Medium | Instead of running migrations locally or exposing direct DB routes to CI/CD, run migrations in a transient ECS Fargate task in the private subnet during the pipeline run |

### 15.6 Key Decision Points for the Team

1. **K8s or not K8s?** — The single highest-leverage decision. If the team doesn't have deep K8s expertise today, switching to ECS Fargate frees up 30-50% of DevOps capacity. If K8s is a deliberate skills investment (e.g., hiring K8s engineers in next quarter), stay the course with EKS.

2. **3 state files or 2?** — The marginal benefit of separating data-stores from apps is low for this scale. The operational cost of apply ordering and remote state references is real. Simplify to 2.

3. **AMI baking or AWS-provided?** — Custom AMIs via Packer add a whole pipeline (Packer + Image Builder + testing). For `t3` instances running standard Node.js/Python apps, AWS-provided Amazon Linux 2023 with user-data scripts is sufficient. Drop Packer until there's a concrete performance or compliance reason to keep it.

4. **Service mesh now or later?** — If EKS is retained, deferring mTLS means internal traffic is unauthenticated. For SOC 2, this may need addressing sooner than planned. App-level mTLS (via mutual TLS in the application code) is a low-effort stopgap.

5. **RDS PostgreSQL vs. Aurora Serverless v2** — Maintain the choice of RDS PostgreSQL for the initial Terraform design to minimize implementation complexity, testing friction, and ensure budget transparency. Use Single-AZ configuration for dev/staging and Multi-AZ for production.

### 15.7 Cost Optimization Opportunities

| Opportunity | Savings | Effort |
|---|---|---|
| Replace EKS with ECS Fargate (smaller team overhead) | ~$73/mo control plane + ~$50-100/mo in node group over-provisioning | Medium |
| NAT instance for dev instead of NAT Gateway | ~$17/mo savings in dev | Low |
| Reduce EKS node count in prod (3 → 2 on-demand, test spot reliability) | ~$50/mo | Low |
| RDS reserved instance (1-year, partial upfront) | ~30% discount on RDS = ~$60/mo | Low |
| Consolidate S3 buckets (app-logs + app-backups + app-assets → 1 bucket with prefixes) | Negligible direct savings, simpler IAM policies | Low |
| **Total potential savings** | **~$200-300/mo** | |

### 15.8 Verdict

**Solid foundation, but simplify before scaling.** The VPC design, IAM architecture, SSM adoption, and security posture are all excellent. The compute strategy is the weak point — three platforms for a 1-2 person team is unsustainable. Consolidating to **ECS Fargate (or at most EC2 ASG + ECS Fargate)** would preserve the architectural vision while making it operable by a small team. The Terraform state strategy should be simplified to 2 files. Everything else (monitoring, secrets, backup, CI/CD) is well-considered.

> **Recommendation:** Proceed with Phase 1 (networking + security + IAM) as-is since those are platform-agnostic. Pause Phase 2 and **re-evaluate the compute architecture decision** (EKS vs. ECS Fargate) before building application-layer modules.

---

## 16. Architecture Flow & Component Connections

### 16.1 User Traffic Flow (Production)

```
                            INTERNET
                               │
                     ┌─────────▼─────────┐
                     │   Route 53 (DNS)   │
                     │ company-small.io   │
                     │ api.company-small  │
                     │ app.company-small  │
                     └─────────┬─────────┘
                               │ DNS resolution
                     ┌─────────▼─────────┐
                     │  AWS WAF (ALB)     │
                     │  Rate limiting     │
                     │  SQLi / XSS rules  │
                     │  IP blocklist      │
                     └─────────┬─────────┘
                               │ TLS 1.3 (ACM cert)
                     ┌─────────▼─────────┐
                     │    ALB (Public)    │
                     │  Internet-facing   │
                     │  2 AZs (HA)       │
                     └──┬──────────┬─────┘
                        │          │
              ┌─────────▼──┐  ┌───▼──────────┐
              │ Workload B  │  │  Workload C   │
              │ ASG API     │  │  EKS Ingress   │
              │ (REST/gRPC) │  │  ALB Ingress   │
              │ t3.large    │  │  Controller    │
              │ min=2 max=6 │  │               │
              └──┬──────────┘  └───┬──────────┘
                 │                 │
       ┌─────────▼─────────────────▼──────────┐
       │         Private Subnets (10.0.11/12)  │
       │  ┌──────────┐  ┌──────────────────┐  │
       │  │ Workload A│  │  EKS Node Group   │  │
       │  │ EC2 Mono  │  │  t3.medium x3 OD  │  │
       │  │ t3.medium │  │  t3.medium x2 SPOT│  │
       │  │ +standby  │  │  user-service,     │  │
       │  │ EFS mount │  │  payment, notify.. │  │
       │  └─────┬─────┘  └────────┬─────────┘  │
       └────────┼──────────────────┼────────────┘
                │                  │
       ┌────────▼──────────────────▼────────────┐
       │           Data Subnets (10.0.21/22)     │
       │                                         │
       │  ┌──────────┐  ┌──────────┐  ┌───────┐ │
       │  │ RDS PG    │  │ Redis    │  │ EFS   │ │
       │  │ Multi-AZ  │  │ cache    │  │ burst │ │
       │  │ encrypted │  │ t3.small │  │ mode  │ │
       │  │ bkup 35d  │  │ encrypt  │  │ encr. │ │
       │  └──────────┘  └──────────┘  └───────┘ │
       │                                         │
       │  ┌──────────────────────────────────┐   │
       │  │   S3 VPC Endpoint (Gateway)       │   │
       │  └──────────────┬───────────────────┘   │
       └─────────────────┼───────────────────────┘
                         │
               ┌─────────▼─────────┐
               │  S3 Buckets        │
               │  app-logs          │
               │  app-backups       │
               │  app-assets        │
               └───────────────────┘
```

### 16.2 Network Traffic Flow (Subnet-Level)

```
                           INTERNET
                              │
                    ┌─────────▼─────────┐
                    │   Public Subnets   │
                    │  10.0.1.0/24 (az-a)│
                    │  10.0.2.0/24 (az-b)│
                    │                    │
                    │  ┌──────┐ ┌─────┐ │
                    │  │ ALB  │ │NAT  │ │
                    │  │ WAF  │ │ GW  │ │
                    │  └──┬───┘ └──┬──┘ │
                    └─────┼─────────┼────┘
                          │         │
              ┌───────────▼─────────▼──────────┐
              │       Private Subnets           │
              │  10.0.11.0/24 (az-a)            │
              │  10.0.12.0/24 (az-b)            │
              │                                 │
              │  Ingress: ALB SG only           │
              │  Egress: NAT GW                 │
              │  Admin: SSM VPC Endpoint        │
              │                                 │
              │  ┌────────┐ ┌───────┐ ┌──────┐ │
              │  │ EC2    │ │ ASG   │ │ EKS  │ │
              │  │ Monolith│ │ API   │ │Nodes │ │
              │  └───┬────┘ └───┬───┘ └──┬───┘ │
              └──────┼──────────┼─────────┼──────┘
                     │          │         │
        ┌────────────▼──────────▼─────────▼──────┐
        │           Data Subnets                  │
        │  10.0.21.0/24 (az-a)                    │
        │  10.0.22.0/24 (az-b)                    │
        │                                         │
        │  Ingress: App Security Groups only      │
        │  No internet route                      │
        │                                         │
        │  ┌─────┐ ┌─────┐ ┌─────┐ ┌──────────┐ │
        │  │ RDS │ │Redis│ │ EFS │ │SecretsMgr│ │
        │  └─────┘ └─────┘ └─────┘ └──────────┘ │
        └─────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   S3 (via VPC     │
                    │   Gateway Endpt)  │
                    └───────────────────┘

LEGEND:
─────►  User traffic / Ingress
- - - ►  Egress (via NAT GW)
~~~~~►  Admin access (SSM VPC Endpoint)
=====►  Data access (internal)
```

### 16.3 CI/CD Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      GITHUB                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Repository: terraform-ws                                │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐               │   │
│  │  │ dev/     │  │ staging/ │  │ prod/    │               │   │
│  │  │ networking│  │ networking│  │ networking│              │   │
│  │  │ data-    │  │ data-    │  │ data-    │               │   │
│  │  │ stores.tf│  │ stores.tf│  │ stores.tf│               │   │
│  │  │ apps.tf  │  │ apps.tf  │  │ apps.tf  │               │   │
│  │  └──────────┘  └──────────┘  └──────────┘               │   │
│  └──────────────────────────────────────────────────────────┘   │
└───────────────────────────┬──────────────────────────────────────┘
                            │ PR (plan) / Merge (apply)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  GITHUB ACTIONS (OIDC)                             │
│                                                                   │
│  ┌─────────────┐    ┌─────────────┐    ┌────────────────────┐   │
│  │ 1. Validate  │    │ 2. Security  │    │ 3. Terraform       │   │
│  │ terraform    │───►│ Checkov      │───►│ Plan / Apply       │   │
│  │ fmt + init   │    │ tfsec        │    │ (per environment)  │   │
│  └─────────────┘    └─────────────┘    └─────────┬──────────┘   │
└───────────────────────────────────────────────────┼────────────────┘
                                                    │ Assume IAM role
                                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS (via OIDC Federation)                      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  GitHub Actions Role (github-actions-role)                   │  │
│  │  Trust: GitHub OIDC                                         │  │
│  │  Permissions: ECR:*, S3:*, IAM:PassRole, SSM:StartSession  │  │
│  └────────────────────┬───────────────────────────────────────┘  │
│                       │                                          │
│          ┌────────────┼────────────┬────────────────┐            │
│          ▼            ▼            ▼                ▼            │
│  ┌────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐      │
│  │ S3 Backend │ │ DynamoDB │ │ Resources│ │ ECR Push     │      │
│  │ (state     │ │ (state   │ │ via      │ │ (if apps     │      │
│  │  files)    │ │  lock)   │ │ modules  │ │  changed)    │      │
│  └────────────┘ └──────────┘ └──────────┘ └──────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │ 3 State Files      │
                    │ (per environment)  │
                    │                    │
                    │  1. networking     │──► VPC, Subnets, NAT, Route53
                    │  2. data-stores    │──► RDS, Redis, EFS, S3
                    │  3. apps           │──► IAM, EC2, ASG, EKS
                    └───────────────────┘
```

### 16.4 Secrets Delivery Flow

```
                     ┌──────────────────────┐
                     │  AWS Secrets Manager  │
                     │                      │
                     │  RDS Credentials      │
                     │  API Keys             │
                     │  3rd Party Tokens     │
                     └──────────┬───────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
         ▼                      ▼                      ▼
┌────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│ Workload A     │  │ Workload B         │  │ Workload C         │
│ EC2 Monolith   │  │ ASG API            │  │ EKS Pods           │
│                │  │                    │  │                    │
│ Boot:          │  │ Boot:              │  │ External Secrets   │
│ user-data      │  │ user-data          │  │ Operator (ESO)     │
│ script runs    │  │ script runs        │  │ synces K8s Secrets │
│ aws ssm get-   │  │ aws ssm get-       │  │ ← Secrets Mgr      │
│ parameters     │  │ parameters         │  │                    │
│ via instance   │  │ via instance       │  │ Auto-refresh       │
│ role           │  │ role               │  │ on 60s poll        │
│                │  │                    │  │                    │
│ Cache to EBS   │  │ Env vars at        │  │ Pods read from     │
│ + cron refresh │  │ app startup        │  │ K8s Secrets        │
└────────────────┘  └────────────────────┘  └────────────────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
                     ┌──────────▼──────────┐
                     │  Auto-Rotation       │
                     │  Lambda (every 30d)  │
                     │  Zero-downtime       │
                     │  updates RDS creds   │
                     │  + updates Secrets   │
                     │  Manager             │
                     └─────────────────────┘
```

### 16.5 Admin Access Flow (SSM Session Manager)

```
┌──────────────────┐
│  Engineer        │
│  (AWS SSO Auth)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│                IAM Identity Center (SSO)                   │
│                                                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │  sre-readonly-role                                  │   │
│  │  Permissions: ReadOnlyAccess + SSM:DescribeSessions │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  IAM Policy: ssm:StartSession → tag:Environment=prod     │
│                         + tag:SSMManaged=true             │
│              ssm:TerminateSession → (own sessions only)   │
└─────────────────────────┬────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│              VPC (via SSM VPC Endpoints)                    │
│                                                            │
│  3 Interface Endpoints (Private Subnets):               │
│  ┌──────────┐  ┌────────────┐  ┌────────────┐          │
│  │ ssm      │  │ ssmmessages│  │ ec2messages│          │
│  │ endpoint │  │ endpoint   │  │ endpoint   │          │
│  └────┬─────┘  └─────┬──────┘  └─────┬──────┘          │
│       └───────────────┼───────────────┘                  │
└───────────────────────┼──────────────────────────────────┘
                        │
          ┌─────────────┼────────────────────┐
          ▼             ▼                    ▼
┌────────────────┐ ┌──────────┐ ┌────────────────────┐
│ Workload A     │ │Workload B│ │ Workload C          │
│ EC2 t3.medium  │ │ASG t3.lrg│ │ EKS Node t3.medium  │
│ SSM Agent      │ │SSM Agent │ │ SSM Agent           │
│ No port 22     │ │No port 22│ │ Via kubectl exec    │
│                │ │          │ │ (aws-auth ConfigMap)│
│ CloudTrail     │ │CloudTrail│ │ CloudTrail logs     │
│ logs every     │ │logs every│ │ SSM session + K8s   │
│ session + cmds │ │session   │ │ audit logs          │
└────────────────┘ └──────────┘ └────────────────────┘
```

### 16.6 Inter-Component Dependency Map

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌───────────┐
│ Route 53 │────►│ ACM Cert │────►│ ALB      │────►│ WAF       │
└──────────┘     └──────────┘     └────┬─────┘     └───────────┘
                                        │
          ┌─────────────────────────────┼──────────────────┐
          │                             │                  │
          ▼                             ▼                  ▼
┌──────────────────┐  ┌─────────────────────┐  ┌──────────────────┐
│ Workload A       │  │ Workload B           │  │ Workload C       │
│ EC2 Monolith     │  │ ASG API              │  │ EKS              │
│ ──────────────── │  │ ──────────────────── │  │ ─────────────── │
│ Needs:           │  │ Needs:               │  │ Needs:           │
│ ├── VPC/Subnet   │  │ ├── VPC/Subnet       │  │ ├── VPC/Subnet   │
│ ├── SG from sec  │  │ ├── SG from sec      │  │ ├── SG from sec  │
│ ├── IAM Role     │  │ ├── IAM Role         │  │ ├── IAM Role     │
│ ├── EFS mount    │  │ ├── AMI (Packer)     │  │ ├── EKS CP IAM   │
│ ├── RDS access   │  │ ├── RDS access       │  │ ├── RDS access   │
│ ├── Redis access │  │ ├── Redis access     │  │ ├── Redis access │
│ └── Secrets Mgr  │  │ ├── Secrets Mgr      │  │ ├── Secrets Mgr  │
└──────────────────┘  │ └── ECR access       │  │ └── ECR access   │
                       └─────────────────────┘  └──────────────────┘
                              │                         │
                              └──────────┬──────────────┘
                                         ▼
                              ┌────────────────────┐
                              │  Data Stores        │
                              │  ──────────────    │
                              │  RDS ◄── App SGs   │
                              │  Redis ◄── App SGs │
                              │  EFS ◄── Mount tgt │
                              │  S3 ◄── VPC Endpt  │
                              └────────────────────┘
                                         ▲
                                         │
                              ┌────────────────────┐
                              │  AWS Backup         │
                              │  ──────────────    │
                              │  RDS daily snap     │
                              │  S3 versioning      │
                              │  EFS backup plan    │
                              │  Cross-region copy  │
                              └────────────────────┘
```

### 16.7 Monitoring & Logging Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────────────┐  │
│  │ EC2      │  │ ASG API  │  │ EKS Pods                     │  │
│  │ Monolith │  │          │  │ (CloudWatch agent sidecar)    │  │
│  └────┬─────┘  └────┬─────┘  └──────────────┬───────────────┘  │
│       │             │                        │                  │
│       │ CW Agent    │ CW Agent               │ FluentD / CW     │
│       ▼             ▼                        ▼                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                  CloudWatch Logs                         │    │
│  │  /aws/ec2/monolith  /aws/asg/api  /aws/eks/pods/*       │    │
│  └──────────────────────────┬────────────────────────────┘     │
└─────────────────────────────┼──────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌──────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ CloudTrail   │  │ VPC Flow Logs    │  │ SSM Session Logs │
│ (Multi-region)│  │ (All subnets)    │  │ (S3 / CW Logs)   │
│ IAM events   │  │ Network traffic  │  │ Admin commands   │
│ API calls    │  │ Accept/Reject    │  │ Who/what/when    │
└──────┬───────┘  └────────┬─────────┘  └────────┬─────────┘
       └───────────────────┼──────────────────────┘
                           ▼
              ┌──────────────────────┐
              │  CloudWatch Alarms    │
              │  ──────────────────  │
              │  CPU > 60% (ASG)     │
              │  RDS connections     │
              │  EKS pod restarts    │
              │  5xx error spike     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  SNS Topic            │
              │  ──────────────────  │
              │  Slack                │
              │  PagerDuty            │
              │  Email (ops team)     │
              └──────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Datadog / Grafana   │
              │  (3rd party)         │
              │  Dashboards          │
              │  APM traces          │
              └──────────────────────┘
```

### 16.8 Data Flow per Request (End-to-End)

```
Step  User Action                    Flow Path
────  ────────────────────────────   ─────────────────────────────────────
 1    User visits app.company-small  Browser → Internet → Route 53
 2    DNS resolution                 Route 53 returns ALB IP (alias record)
 3    TLS handshake                  ALB terminates TLS via ACM cert
 4    WAF inspection                 WAF checks rate limit, SQLi, XSS, IP
 5    Load balancing                 ALB routes to target group
 6a   If API request (Workload B)    ALB → ASG EC2 instance (private subnet)
 6b   If admin panel (Workload A)    ALB → EC2 monolith (private subnet)
 6c   If microservice (Workload C)   ALB → ALB Ingress Controller → Pod
 7    Auth check                     App validates JWT / session token
 8    Data access                    App → RDS/Redis/EFS/S3 (data subnet)
 9    Secrets fetch                  App → Secrets Manager via IAM role
10    Response                       App → ALB → Internet → User

Traffic isolation per subnet tier:
  Public Subnet:   Only ALB and NAT Gateway see internet traffic
  Private Subnet:  Apps receive traffic only from ALB SG
  Data Subnet:     Databases receive traffic only from App SGs
  S3:              Accessed via VPC Gateway Endpoint (no NAT traversal)
  Internet egress: Via NAT Gateway (only for app outbound calls)
```

### 16.9 Backup & Disaster Recovery Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  PRODUCTION (us-east-1)                            │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │ RDS      │  │ EFS      │  │ S3       │                     │
│  │ Automated│  │ Backup   │  │ Versioned│                     │
│  │ backups  │  │ plan     │  │ + CRR    │                     │
│  │ 35d ret. │  │ daily    │  │          │                     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                     │
│       │             │             │                            │
│       └─────────────┼─────────────┘                            │
│                     │                                           │
│            ┌────────▼────────┐                                  │
│            │  AWS Backup      │                                 │
│            │  Backup Vault    │                                 │
│            │  + Vault Lock    │                                 │
│            │  (compliance)    │                                 │
│            └────────┬────────┘                                  │
│                     │                                           │
│                     │ Cross-region copy                         │
└─────────────────────┼───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                  DR REGION (us-west-2)                             │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────────────┐  │
│  │ RDS      │  │ S3       │  │ Backup Vault (DR copy)        │  │
│  │ snapshots│  │ replicated│  │  ─────────────────────────  │  │
│  │ (encrypt)│  │ (CRR)    │  │  RDS snapshots               │  │
│  └──────────┘  └──────────┘  │  EFS backups                 │  │
│                               │  S3 object copies            │  │
│                               └──────────────────────────────┘  │
│                                                                   │
│  Recovery Steps (RTO: 4h, RPO: 1h):                              │
│  1. Promote RDS snapshot to new instance                          │
│  2. Deploy networking stack (pre-baked Terraform)                 │
│  3. Deploy apps pointing to DR RDS endpoint                       │
│  4. Update Route 53 DNS → DR ALB                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 16.10 Terraform State & Module Dependency Flow

```
                            ┌──────────────┐
                            │  providers.tf │
                            │  + backend.tf │
                            └──────┬───────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │  1. networking.tfstate       │
                    │  ───────────────────────    │
                    │  VPC CIDR: 10.0.0.0/16      │
                    │  Public Subnets (10.0.1-2)   │
                    │  Private Subnets (10.0.11-12)│
                    │  Data Subnets (10.0.21-22)   │
                    │  NAT Gateways (x2)           │
                    │  Route Tables + Routes       │
                    │  VPC Flow Logs               │
                    │  SSM VPC Endpoints (x3)      │
                    │  Route53 Zone + Records      │
                    │  ACM Certificates            │
                    └──────────────┬───────────────┘
                                   │ terraform_remote_state
                                   │ (VPC ID, Subnet IDs, SG IDs)
                                   ▼
                    ┌──────────────▼──────────────┐
                    │  2. data-stores.tfstate      │
                    │  ───────────────────────    │
                    │  RDS PostgreSQL             │
                    │  ElastiCache Redis          │
                    │  EFS File System            │
                    │  S3 Buckets (3) + Policies  │
                    │  Secrets Manager + Rotation │
                    └──────────────┬───────────────┘
                                   │ terraform_remote_state
                                   │ (DB endpoint, Redis endpoint, 
                                   │  EFS ID, bucket names, secret ARNs)
                                   ▼
                    ┌──────────────▼──────────────┐
                    │  3. apps.tfstate             │
                    │  ───────────────────────    │
                    │  ┌──────────────────────┐   │
                    │  │ IAM                   │   │
                    │  │ Roles, Policies, OIDC │   │
                    │  └──────────┬───────────┘   │
                    │             │               │
                    │  ┌──────────▼───────────┐   │
                    │  │ ec2-legacy module    │   │
                    │  │ (depends on all      │   │
                    │  │  above)              │   │
                    │  └──────────┬───────────┘   │
                    │             │               │
                    │  ┌──────────▼───────────┐   │
                    │  │ asg-api module       │   │
                    │  │ (depends on all      │   │
                    │  │  above)              │   │
                    │  └──────────┬───────────┘   │
                    │             │               │
                    │  ┌──────────▼───────────┐   │
                    │  │ eks module            │   │
                    │  │ (depends on all       │   │
                    │  │  above)               │   │
                    │  └──────────┬───────────┘   │
                    │             │               │
                    │  ┌──────────▼───────────┐   │
                    │  │ ssm + monitoring     │   │
                    │  │ (depends on apps)    │   │
                    │  └─────────────────────┘   │
                    └────────────────────────────┘

Apply Order:  networking  →  data-stores  →  apps
Destroy Order:  apps  →  data-stores  →  networking
```

### 16.11 Component Connection Matrix

| Source | Destination | Protocol | Port | Via | Auth |
|--------|------------|----------|------|-----|------|
| **Internet** | Route 53 | DNS | 53 | Public internet | None (public DNS) |
| **Internet** | ALB (Public) | HTTPS | 443 | Internet → Public Subnet | ACM TLS cert |
| **ALB** | WAF | HTTPS | 443 | Same ALB | N/A (ALB-integrated) |
| **ALB** | EC2 Monolith (A) | HTTP/HTTPS | 8080 | Public → Private Subnet | SG: ALB SG only |
| **ALB** | ASG Instance (B) | HTTP/gRPC | 8080/50051 | Public → Private Subnet | SG: ALB SG only |
| **ALB Ingress** | EKS Pod (C) | HTTP | 80/443 | Public → Private → K8s | SG + K8s RBAC |
| **App → RDS** | RDS PostgreSQL | PostgreSQL | 5432 | Private → Data Subnet | SG: App SG + IAM auth |
| **App → Redis** | ElastiCache Redis | Redis | 6379 | Private → Data Subnet | SG: App SG + AUTH token |
| **App → EFS** | EFS (Workload A) | NFSv4 | 2049 | Private Subnet mount | SG: Mount target SG |
| **App → S3** | S3 (all workloads) | HTTPS | 443 | VPC Gateway Endpoint | IAM Role (S3ReadOnly) |
| **App → Secrets** | Secrets Manager | HTTPS | 443 | Data Subnet | IAM Role (scoped ARN) |
| **EKS Pod → K8s API** | EKS Control Plane | HTTPS | 443 | Private subnet endpoint | IAM + aws-auth ConfigMap |
| **Admin (SSO)** → SSM | SSM VPC Endpoint | HTTPS | 443 | Internet → Private Subnet | IAM Identity Center |
| **SSM** → EC2/EKS | SSM Agent | WSS | 443 | SSM Endpoint → Private | IAM StartSession policy |
| **NAT GW** → Internet | Internet egress | Any | Any | Private → Public → NAT → IGW | Source NAT (ephemeral) |
| **Backup** → RDS | AWS Backup service | API | 443 | Data Subnet | IAM backup-role |
| **CloudWatch Agent** | CloudWatch Logs | HTTPS | 443 | Private → CW Interface Endpt | IAM instance role |

### 16.12 Environment Isolation Strategy

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   DEV         │    │  STAGING      │    │  PROD         │
│  ─────────    │    │  ─────────    │    │  ─────────    │
│  Single-AZ    │    │  Single-AZ    │    │  Multi-AZ     │
│  t3.micro RDS │    │  t3.small RDS │    │  t3.medium    │
│  1 NAT GW     │    │  1 NAT GW     │    │  2 NAT GWs    │
│  1 ec2        │    │  1 ec2        │    │  active+stby  │
│  ASG min=1    │    │  ASG min=1    │    │  ASG min=2    │
│  EKS 1 node   │    │  EKS 2 nodes  │    │  EKS 5 nodes  │
│  7d backups   │    │  14d backups  │    │  35d backups  │
│  ~$250/mo     │    │  ~$400/mo     │    │  ~$993/mo     │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
               ┌───────────▼───────────┐
               │  Terraform Workspaces  │
               │  or Root Modules       │
               │                        │
               │  Same modules/         │
               │  Different variables   │
               │  Different state files │
               └───────────────────────┘
```

---

## 17. Consolidated Analysis & Next Steps

### 17.1 Finalized Architectural Decisions (The Baseline)

| Decision | Choice | Rationale |
|---|---|---|
| **Compute strategy** | Maintain 3-platform (EC2 Monolith + ASG API + EKS Microservices) | Noted recommendation to consolidate toward ECS Fargate in future cycles to ease management |
| **Database** | RDS PostgreSQL (Multi-AZ Prod, Single-AZ non-prod) | Testing simplicity, predictable billing; Aurora Serverless deferred |
| **Access control** | Fully SSH-free via AWS SSM Session Manager | Reduces network attack surface; eliminates key management |
| **Secrets management** | SSM Parameter Store (VMs) + External Secrets Operator (EKS) | Workload-appropriate delivery; no hardcoded secrets |
| **Compliance posture** | AWS Backup Vault Lock (compliance mode) + CloudWatch log lifecycle limits + S3 Object-Locked Glacier archives | SOC 2 evidence requirements met |

### 17.2 Primary Residual Risks (Post-V4 Review)

| Risk | Impact | Required Action | Priority |
|---|---|---|---|
| **Private IP exhaustion** — EKS CNI assigns dedicated IPs per pod; `/24` subnets (251 IPs) exhaust quickly with multiple namespaces/services | Pod scheduling failures; blocked deployments | Configure `/22` private subnets or enable VPC CNI prefix delegation in Terraform from day one | **P0** |
| **EFS monolith stalls** — Default Bursting throughput mode causes latency spikes on directory-heavy monolith operations (Workload A) | Application timeouts; degraded admin panel UX | Enable Elastic Throughput mode in the EFS module; do not rely on Bursting | **P0** |
| **State drift & orchestration friction** — 3-state-file config (networking → data-stores → apps) requires careful apply ordering; downstream changes (e.g., SG replacement) can break references | Deployments blocked; manual intervention required | Use SSM Parameter Store as loose coupler instead of direct `terraform_remote_state` for cross-stack references | **P1** |
| **Secrets propagation lag** — ESO 60s poll interval means rotated creds cause transient auth failures | Auth errors on pod restarts after rotation | Reduce poll interval; add application-level retry with backoff | **P2** |
| **vCPU account limits** — Default limits (5-20 vCPUs) may block ASG/EKS scaling | Scaling blocked during traffic spikes | Request limit increases during Phase 1 before launch | **P1** |
| **No DR runbook tested** — Cross-region backups exist but recovery procedure is undocumented | RTO/RPO undefined; recovery time unpredictable | Document DR runbook with RTO=4h, RPO=1h; test failover quarterly | **P2** |

### 17.3 Actionable Terraform Coding Plan (Phase 1)

The implementation must proceed in strict dependency order. Each module must write critical outputs to SSM Parameter Store before downstream modules are applied, avoiding tight `terraform_remote_state` coupling.

```
Phase 1a ── networking Module (FIRST)
├── VPC with /22 private subnets (prevent EKS IP exhaustion)
├── Public /24 subnets (ALB + NAT Gateway placement)
├── Data /24 subnets (RDS, Redis, EFS placement)
├── NAT Gateways (1 for dev/staging, 2 for prod)
├── Route tables + explicit NACLs per tier
├── VPC Flow Logs (all subnets)
├── SSM VPC Endpoints (ssm, ssmmessages, ec2messages)
├── Route53 public zone + ACM certificates
├── S3 Gateway Endpoint
└── WRITE TO SSM: vpc_id, subnet_ids, sg_ids, nat_gw_ids

Phase 1b ── security Module (SECOND)
├── KMS Customer Managed Keys (CMK) for:
│   ├── RDS encryption
│   ├── EBS encryption
│   ├── EFS encryption
│   ├── S3 encryption
│   └── Secrets Manager
├── Baseline Security Groups (read SG IDs from SSM)
│   ├── alb-sg (ingress: 0.0.0.0/0:443)
│   ├── private-app-sg (ingress: alb-sg)
│   ├── data-sg (ingress: private-app-sg)
│   └── ssm-endpoint-sg
├── ACM certificate request + DNS validation
└── WRITE TO SSM: kms_key_arns, sg_ids, acm_arn

Phase 1c ── iam Module (THIRD)
├── IAM Identity Center (SSO) setup
├── GitHub Actions OIDC provider + trust relationship
├── IAM Roles:
│   ├── ec2-legacy-role (SSM + S3ReadOnly + CWAgent + SecretsRead)
│   ├── asg-api-role (same + ECRReadOnly)
│   ├── eks-node-role (EKS worker + CNI + SSM)
│   ├── eks-cluster-role (AmazonEKSClusterPolicy)
│   ├── github-actions-role (ECR + S3 + IAM:PassRole)
│   ├── backup-role (AWSBackupServiceRolePolicy)
│   └── sre-readonly-role (ReadOnlyAccess + SSM:Describe)
├── Instance profiles for EC2 roles
├── SSM StartSession policies (tag-scoped)
└── WRITE TO SSM: role_arns, instance_profile_names, oidc_provider_arn
```

### 17.4 Module Coding Guidelines

| Guideline | Detail |
|---|---|
| **No hardcoded IDs** | All cross-module references read from SSM Parameter Store, not `terraform_remote_state` |
| **Environment variables** | `rds_multi_az`, `nat_gw_count`, `asg_min_size`, `eks_node_desired` as module inputs with defaults matching dev |
| **Tags** | Every resource tagged: `Environment`, `ManagedBy=Terraform`, `Project=company-small` |
| **Sensitive outputs** | Database endpoints, secret ARNs, and IAM role ARNs marked `sensitive = true` |
| **Lifecycle policies** | `prevent_destroy = true` on RDS, S3 buckets, and KMS keys to prevent accidental deletion |
| **Backend config** | S3 bucket + DynamoDB lock table per environment; backend config not hardcoded (passed at init) |
| **Retention defaults** | CloudWatch Log Group retention = 30 days; S3 Intelligent-Tiering for logs bucket |
| **Checkov/tfsec** | `checkov.yml` and `.tfsec` config committed alongside code; CI gates on critical/high findings |

### 17.5 Quick-Start Sequence

```bash
# Step 1: Bootstrap S3 backend + DynamoDB lock table (once per env)
aws s3 mb s3://company-small-tfstate-{env}
aws dynamodb create-table --table-name terraform-lock-{env} --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST

# Step 2: Deploy networking
cd environments/{env} && terraform init -backend-config=bucket=company-small-tfstate-{env} -backend-config=key=networking/terraform.tfstate
terraform apply -target=module.networking

# Step 3: Verify SSM parameters were written
aws ssm get-parameters --names /company-small/{env}/networking/vpc_id --query Parameters[0].Value

# Step 4: Deploy security (reads networking outputs from SSM)
terraform apply -target=module.security

# Step 5: Deploy IAM (reads SG IDs, KMS ARNs from SSM)
terraform apply -target=module.iam

# Step 6: Verify full stack
terraform apply  # remaining resources
```

### 17.6 Phase 1 Exit Criteria

- [ ] `networking` module creates VPC with `/22` private subnets, NAT Gateways, SSM endpoints, Route53 zone, ACM certs
- [ ] `security` module creates KMS CMKs, baseline SGs, ACM cert with DNS validation
- [ ] `iam` module creates all 7 IAM roles, OIDC provider, SSM policies
- [ ] All cross-module references use SSM Parameter Store (no `terraform_remote_state`)
- [ ] CI pipeline runs `terraform validate` + `checkov` + `tfsec` with zero critical/high failures
- [ ] SSM Session Manager access works for all EC2 instances in private subnets
- [ ] GitHub Actions OIDC role assumes correctly and can run `terraform plan`
- [ ] Environment variable overrides work for dev/staging/prod sizing

---

*Last updated: 2026-06-15 (v6 — Consolidated analysis & Phase 1 coding plan added)*
*Author: Infra Planning & AI Review*
