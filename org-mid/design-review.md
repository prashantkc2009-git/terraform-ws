Reviewed `/app/workspace/terraform-ws/org-mid/company-mid.md`.
Status: Pending Analysis
Version: REVIEW 1.0

## Executive summary

The document is strong as a mid-size AWS target architecture: it has clear multi-account separation, DR thinking, workload categorization, security controls, CI/CD guardrails, and ADRs. It reads like a realistic Series B/C platform blueprint.

Main concern: **the design is operationally too heavy for a 3–5 person SRE team** unless scope is phased aggressively. The biggest risks are complexity, cost accuracy, DR overconfidence, compliance gaps, and a few internal inconsistencies around EKS topology, budget, networking, and failover assumptions.

---

## Major pros

### 1. Good multi-account foundation

The account split is sensible:

- Management
- Security
- Log Archive
- Shared Services
- Dev
- Staging
- Prod
- Data Analytics

This gives good blast-radius control and maps well to SOC 2 / PCI / HIPAA expectations.

### 2. Clear workload segmentation

The five workload families are well-defined:

- Customer APIs
- Async/event processing
- Data/analytics
- Frontend/edge
- Internal tools

This helps Terraform module boundaries, ownership, IAM scoping, and future scaling.

### 3. Good security-first defaults

Strong choices:

- IAM Identity Center + Okta
- No long-lived human keys
- GitHub OIDC
- SCPs
- GuardDuty / Security Hub / Inspector / Macie
- CloudTrail / Config org-wide
- KMS encryption
- WAF + Shield Advanced
- Secrets Manager + ESO
- Kyverno admission policies
- Cilium network policies

The security posture is mature for a mid-size company.

### 4. Solid DR intent

Aurora Global Database, cross-region backups, CRR, Route53 failover, and tabletop drills are good building blocks.

The document correctly avoids active-active multi-region DB complexity in Phase 1.

### 5. Good engineering process controls

The CI/CD and Terraform controls are good:

- PR-only infrastructure changes
- `terraform fmt`
- `tflint`
- `checkov`
- Terratest
- Staging-first promotion
- Manual production gate
- Canary rollout
- Vulnerability blocking

This is a good baseline for controlled growth.

---

## Major risks

## 1. Operational complexity is very high

For 3–5 SREs, this stack is heavy:

- Multi-account AWS Organizations
- Transit Gateway
- Centralized egress
- Multiple EKS clusters
- Karpenter
- Cilium
- Istio
- Kyverno
- Thanos
- Prometheus/Grafana
- OpenSearch Serverless
- X-Ray
- MSK
- MWAA
- Redshift
- SageMaker
- Aurora Global Database
- Shield Advanced
- Firewall Manager
- AWS Backup
- Cross-region replication
- GitHub runners on EKS

This is closer to a large-company platform than a lean mid-size setup.

**Risk:** SRE team becomes a bottleneck. Upgrades, outages, compliance evidence, cost controls, and incident response may overwhelm the team.

**Suggestion:** Split implementation into phases:

- **Phase 1:** AWS Organizations, accounts, baseline security, VPCs, EKS, Aurora, S3, CI/CD, observability minimum.
- **Phase 2:** TGW central egress, Istio, Thanos, MSK, MWAA.
- **Phase 3:** SageMaker, Redshift expansion, advanced DR automation, Firewall Manager, deeper compliance automation.

---

## 2. Budget estimate may be optimistic

The assumed AWS budget is **$35k–$60k/month**, but the total all-inclusive estimate is **~$31.5k/month**.

That is probably too low for this architecture.

Likely undercounted items:

- NAT/TGW data processing at scale
- Cross-region replication
- CloudFront traffic
- WAF Bot Control request pricing
- OpenSearch Serverless ingestion/storage
- MSK storage and broker scaling
- MWAA costs
- SageMaker Studio/training/GPU inference
- EKS node costs across all environments
- Data transfer between accounts/regions
- AWS Config rule evaluations
- CloudWatch Logs ingestion
- VPC Flow Logs volume
- GuardDuty/Macie/Inspector scanning
- Enterprise Support minimums / tiered pricing
- GitHub Enterprise, Okta, PagerDuty actual seat costs
- Backup restore testing environments

**Suggestion:** Add three cost bands:

| Scenario | Monthly Estimate |
|---|---:|
| Lean baseline | $30k–$40k |
| Realistic steady state | $45k–$70k |
| Heavy traffic / ML / analytics | $80k+ |

Also add cost owners and budgets per account.

---

## 3. DR target is overconfident

The document says:

- Customer API RTO: **5 min**
- RPO: **<1s**
- Strategy: Aurora Global Database + DNS failover

Aurora Global Database can help with low replication lag, but **RTO is not solved by database replication alone**.

The app also needs:

- EKS workloads running in DR
- Container images available in DR
- Secrets replicated
- KMS keys usable
- Redis/ElastiCache recovery plan
- MSK/Kafka recovery plan
- DNS TTL behavior understood
- CloudFront origin failover configured
- API Gateway / ALB / WAF replicated
- External dependencies tested
- Runbooks rehearsed

Route53 DNS failover may also not guarantee users move within 5 minutes due to resolver caching.

**Suggestion:** Change the Customer API target unless you are building warm standby:

- If DR is backup/restore: RTO likely **1–4 hours**
- If pilot light: RTO likely **30–60 min**
- If warm standby: RTO **5–15 min**
- If active-active: RTO near-zero but much more expensive/complex

If keeping 5-minute RTO, explicitly define DR as **warm standby** with pre-running EKS, ALB, CloudFront origins, replicated secrets, and tested promotion automation.

---

## 4. Compliance scope is incomplete

The doc mentions SOC 2 Type II, PCI DSS Level 1, HIPAA, and ISO 27001 in-progress.

But it defers:

- Formal data classification matrices
- Pen-test scheduling
- Global data sovereignty
- Some governance details to the security wiki

That is risky.

For PCI/HIPAA/SOC 2, infra design should not fully outsource these to a wiki. The Terraform/platform blueprint needs at least references and enforcement hooks.

**Suggestion:** Add a compliance section with:

- Data classification levels
- Systems in PCI scope
- Systems in HIPAA/PHI scope
- Encryption requirements by data class
- Log retention policy
- Access review cadence
- Break-glass process
- Evidence collection process
- Pen-test cadence
- Vendor risk ownership
- Audit artifact locations

---

## 5. EKS topology has inconsistencies

The document says:

- Workload A has 3 EKS clusters: `platform`, `customer-api`, `internal`
- Account structure says Prod has 2 clusters: `customer-api` and `internal`
- Cost section says 6 control planes: Prod/Staging/Shared/Data
- Data account has `analytics-spark` EKS
- Shared Services has GitHub runners on EKS

The total cluster count is unclear.

Possible count:

- Shared Services runner/platform cluster
- Dev cluster(s)
- Staging cluster(s)
- Prod customer-api
- Prod internal
- Data analytics-spark
- Maybe platform cluster

That could be **6–8+ clusters**, not clearly stated.

**Suggestion:** Add a cluster inventory table:

| Cluster | Account | Region | Purpose | Criticality | Owner |
|---|---|---|---|---|---|
| shared-runners | Shared Services | us-east-1 | CI/CD | Medium | SRE |
| prod-customer-api | Prod | us-east-1 | Customer APIs | Critical | SRE/backend |
| prod-internal | Prod | us-east-1 | Admin/internal tools | High | SRE |
| data-spark | Data | us-east-1 | Analytics jobs | Medium | Data/ML |
| staging-main | Staging | us-east-1 | Pre-prod | Medium | SRE |
| dev-main | Dev | us-east-1 | Dev workloads | Low | SRE |

Then align cost estimates with that table.

---

## 6. VPC subnet design may reduce high availability

In the production VPC example:

- `10.30.16.0/20` says EKS platform pods/nodes in AZ A
- `10.30.32.0/20` says customer-api pods/nodes in AZ B
- `10.30.48.0/20` says internal pods/nodes in AZ C

That reads like each workload/cluster maps to a single AZ. If so, that is a high-availability problem.

Each EKS cluster should span multiple AZs. Subnets should be grouped by tier and AZ, not by cluster per AZ.

**Suggestion:** Change to something like:

```text
Private App Subnets:
10.30.16.0/20 us-east-1a
10.30.32.0/20 us-east-1b
10.30.48.0/20 us-east-1c

Data Subnets:
10.30.64.0/22 us-east-1a
10.30.68.0/22 us-east-1b
10.30.72.0/22 us-east-1c
```

Then allow all critical EKS node groups/Karpenter node pools to use all private app subnets.

---

## 7. Centralized egress trade-off may be understated

ADR-02 says centralized egress saves NAT Gateway hourly costs, but introduces TGW data processing fees.

That is true, but for high-traffic systems, central egress can become more expensive and fragile than local NAT.

Risks:

- TGW data processing fees
- Central NAT bottleneck
- Shared blast radius
- More complex routing
- Harder troubleshooting
- Cross-AZ data transfer surprises
- Failure of shared egress impacts many accounts

**Suggestion:** Do a volume-based comparison:

- Low egress accounts: central NAT may save money
- High egress prod/data accounts: local NAT may be cheaper/simpler
- S3/DynamoDB: use gateway endpoints regardless
- ECR/KMS/CloudWatch/STS/Secrets Manager: use interface endpoints where justified

Consider a hybrid model: central egress for dev/staging/shared, local egress for prod/data high-throughput paths.

---

## 8. Istio may be too heavy

Istio is selected for PCI-grade mTLS, canaries, and granular policies.

That may be valid, but Istio adds serious operational burden:

- Sidecar injection issues
- Upgrade complexity
- Debugging complexity
- Latency overhead
- Certificate rotation issues
- More difficult incident response
- App teams need mesh knowledge

**Suggestion:** Validate whether full Istio is truly required in Phase 1.

Alternatives:

- AWS App Mesh — less common now, but AWS-integrated
- Linkerd — simpler mTLS/service mesh
- Cilium service mesh / Gateway API — may reduce stack overlap
- ALB weighted target groups + Argo Rollouts — for canary without full mesh
- mTLS at ingress + network policies — simpler if internal east-west mTLS is not mandatory yet

If keeping Istio, add a dedicated operational runbook and owner.

---

## 9. MSK + SQS + SNS + Step Functions + MWAA may be too broad

The event/data platform includes:

- MSK
- SQS
- SNS
- Step Functions
- MWAA
- Kinesis Data Analytics
- Spark on EKS
- SageMaker
- Redshift

This is powerful but sprawling.

**Risk:** Teams may choose different tools inconsistently, creating a fragmented platform.

**Suggestion:** Add decision rules:

| Use case | Preferred service |
|---|---|
| Simple async job | SQS + Lambda/EKS worker |
| Fanout notification | SNS |
| Business workflow | Step Functions |
| High-throughput event stream | MSK |
| Data pipeline orchestration | MWAA |
| Real-time stream analytics | Kinesis Data Analytics |
| Batch transformation | Spark on EKS / EMR |
| Warehouse analytics | Redshift |

This prevents every team from picking Kafka for everything.

---

## 10. Security controls need implementation details

The SCP list is good, but some policies are hard to implement broadly without exceptions.

Examples:

- “Require KMS encryption on all resources”
- “Deny public S3/RDS/Redshift access”
- “Deny IAM access key creation humans”
- “Require IMDSv2”
- “Restrict instance types”

These need exception paths and testing.

**Suggestion:** Add:

- SCP exception strategy
- Break-glass role design
- Permission boundary examples
- Policy-as-code tests
- Deployment order
- Account bootstrap sequence
- How to prevent locking out automation roles

---

## 11. Secrets Manager strategy is sane, but ESO risk should be called out

AWS Secrets Manager + External Secrets Operator is a good choice.

Risks:

- ESO compromise can expose many secrets
- Kubernetes RBAC mistakes can leak secrets between namespaces
- Secrets are eventually materialized as Kubernetes Secrets unless using CSI mounts
- Rotation can break apps that do not reload credentials correctly
- High API costs if polling intervals are aggressive

**Suggestions:**

- Use namespace-scoped SecretStores where possible
- Avoid cluster-wide secret access
- Use short refresh intervals only where needed
- Prefer Secrets Store CSI Driver for highly sensitive workloads
- Add app credential reload requirements
- Add secret access audit dashboards

---

## 12. Observability stack could be simplified

The proposed stack:

- OpenSearch Serverless
- Thanos
- Prometheus
- Grafana
- X-Ray
- CloudWatch
- PagerDuty

This is good but heavy.

**Risk:** The team spends more time running observability than using it.

**Suggestion:** Define minimum viable observability:

Phase 1:

- CloudWatch metrics/logs
- Managed Prometheus or Prometheus + Grafana
- X-Ray/OpenTelemetry for critical paths
- PagerDuty alerts
- SLO burn-rate alerts for 3–5 critical services

Phase 2:

- Thanos long-term storage
- OpenSearch log analytics
- Advanced tracing
- Custom dashboards

---

## Suggested document improvements

### 1. Add implementation phases

The doc says some things are out of scope, but the remaining Phase 1 is still very large.

Add a clear phased roadmap:

| Phase | Scope | Exit criteria |
|---|---|---|
| Phase 0 | Org/accounts/security baseline | Accounts, SCPs, CloudTrail, Config, IAM Identity Center |
| Phase 1 | Prod platform MVP | VPC, EKS, Aurora, CI/CD, basic observability |
| Phase 2 | Scale/security hardening | TGW, central egress, WAF automation, backup automation |
| Phase 3 | Data/ML platform | Redshift, MWAA, SageMaker, Spark |
| Phase 4 | DR maturity | Warm standby, failover drills, automated runbooks |

---

### 2. Add “non-negotiables” vs “nice-to-haves”

For a mid-size company, this helps scope.

**Non-negotiable:**

- Multi-account baseline
- CloudTrail/Config/GuardDuty
- IAM Identity Center
- Prod/staging separation
- Backups
- CI/CD controls
- Encryption
- Basic SLOs

**Nice-to-have / later:**

- Full Istio
- Thanos
- OpenSearch Serverless
- Centralized egress
- SageMaker Studio
- MWAA
- Redshift RA3
- Firewall Manager
- Shield Advanced unless threat model justifies it

---

### 3. Clarify account bootstrap order

Recommended order:

1. Create OUs/accounts
2. Configure delegated admins
3. Configure CloudTrail/Config/GuardDuty/Security Hub
4. Configure IAM Identity Center
5. Apply safe baseline SCPs
6. Create log archive buckets/Object Lock
7. Create networking
8. Create shared services
9. Create workload accounts
10. Deploy EKS/data services
11. Add stricter SCPs after validation

This prevents lockout and circular dependency issues.

---

### 4. Add Terraform state design

The doc mentions Terraform testing but not state management.

Add:

- Backend location
- State bucket account
- KMS key ownership
- DynamoDB lock table
- Per-account/per-region state separation
- State access model
- Break-glass process
- Drift detection cadence
- Terraform apply role naming

Example:

```text
s3://company-mid-terraform-state/security/org-baseline.tfstate
s3://company-mid-terraform-state/shared-services/network/us-east-1.tfstate
s3://company-mid-terraform-state/prod/eks/customer-api.tfstate
```

---

### 5. Add ownership boundaries

The RACI is good, but each platform component needs an owner.

Add an ownership table:

| Component | Primary owner | Backup owner | Runbook |
|---|---|---|---|
| EKS | Platform/SRE | Backend lead | `/runbooks/eks.md` |
| Aurora | Backend | SRE | `/runbooks/aurora.md` |
| MSK | Platform/SRE | Data | `/runbooks/msk.md` |
| Redshift | Data | SRE | `/runbooks/redshift.md` |
| WAF | Security | SRE | `/runbooks/waf.md` |
| CI/CD | Platform/SRE | Security | `/runbooks/cicd.md` |

---

## Recommended risk register

| Risk | Severity | Likelihood | Recommendation |
|---|---:|---:|---|
| SRE team overloaded by platform complexity | High | High | Phase rollout; reduce Phase 1 scope |
| DR target not actually achievable | High | Medium | Define warm standby requirements and test quarterly |
| Budget underestimated | High | High | Build detailed AWS Pricing Calculator model |
| Compliance controls incomplete | High | Medium | Add compliance evidence/control matrix |
| Istio operational burden | Medium/High | High | Validate need; consider lighter rollout |
| Centralized egress blast radius | Medium/High | Medium | Hybrid egress model; failure testing |
| EKS cluster count unclear | Medium | High | Add cluster inventory and cost alignment |
| Subnet design could harm HA | High | Medium | Redesign subnets by AZ/tier, not workload |
| Secrets exposure via ESO misconfig | High | Medium | Namespace scoping, RBAC, CSI for sensitive apps |
| Tool sprawl in async/data platform | Medium | High | Add service selection decision matrix |

---

## Final verdict

The document is a strong architecture blueprint, but it currently describes an ambitious mature-platform target more than a safe Phase 1 build.

My recommendation:

1. **Keep the architecture direction.**
2. **Reduce Phase 1 scope.**
3. **Clarify EKS/account/network inconsistencies.**
4. **Rework DR claims to match actual standby posture.**
5. **Recalculate costs with realistic traffic, logging, and data-transfer assumptions.**
6. **Add compliance/control evidence mapping.**
7. **Explicitly decide whether Istio, Thanos, MWAA, Redshift, and central egress are Phase 1 or later.**

If this were going to implementation, I would not approve it as a single Terraform delivery. I would approve it as a **target-state architecture**, then require a phased implementation plan with cost gates, operational readiness checks, and DR validation before production launch.