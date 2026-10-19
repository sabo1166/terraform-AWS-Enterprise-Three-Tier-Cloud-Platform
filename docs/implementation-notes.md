# Implementation notes

## Phase log

| Phase | Scope | Result |
|---|---|---|
| 1 | Git repo, `.gitignore`, `bootstrap/` state bucket, `envs/dev` skeleton and S3 backend stub | Configured; validated offline |
| 2 | VPC, subnets, routing, NAT (`nat_mode`), S3 endpoint, security groups | Configured; validated offline |
| 3 | App S3 bucket, EC2 role and instance profile | Configured; validated offline |
| 4 | Private RDS MySQL, DB credential read permission | Configured; validated offline |
| 5+ | ALB, EC2 Auto Scaling, CloudWatch, optional CloudFront/WAF | Not started |

"Validated offline" means `terraform fmt -check -recursive` and `terraform validate`
(after `terraform init -backend=false`) succeeded. **No plan, apply or backend init has been
run; no AWS resource exists as a result of this repository.**

## Repository layout

```
bootstrap/        state bucket (own local state, applied once)
envs/dev/         dev environment
  versions.tf  providers.tf  variables.tf  locals.tf  outputs.tf
  network.tf  security_groups.tf  storage.tf  iam.tf  database.tf
  backend.hcl.example  terraform.tfvars.example
docs/             this documentation
```

Files are grouped by concern and kept flat. There is no `modules/` directory: with a single
environment a module would add indirection without reuse. Revisit when `envs/prod` is added.

## Conventions
- Names: `${project}-${environment}-<component>` via `local.name_prefix`.
- `for_each` over AZ-keyed maps (`az1`, `az2`); no `count` on collections.
- Variables carry descriptions, types and validation; no secrets in variables.
- Providers and the backend are configured only in the environment root.

## Cost drivers (estimates not verified; check regional pricing)
- NAT gateway: hourly charge plus per-GB processing; the largest idle cost. `per_az` doubles it.
- RDS: instance class dominates; `db_multi_az = true` roughly doubles it. Storage and
  backup storage above the instance size are extra.
- Secrets Manager: small per-secret monthly charge.
- S3 versioning: noncurrent versions accrue storage until a lifecycle rule exists.
- Coming later: ALB hourly and LCU charges, EC2 instances, CloudWatch, optional WAF.

## Operating notes
- Before `envs/dev` can use the remote backend, `bootstrap/` must be applied and
  `backend.hcl` created from `backend.hcl.example`.
- To destroy the dev database: set `db_deletion_protection = false`, apply, then destroy. The
  final snapshot name is fixed, so a repeat destroy needs the old snapshot removed first.
- Clients connecting to MySQL must use TLS.

## Unresolved risks
- Plan output and resource counts have never been observed; first `plan` may surface
  provider or region issues (e.g. engine or instance class availability).
- AWS provider is pinned to `~> 5.0`; the lock files record the version resolved at the time
  of validation.
- Region default (`us-east-1`) is an assumption; account contents are unknown.
- The dev environment's ALB is planned HTTP-only; HTTPS needs a domain and ACM certificate.
- Session Manager permissions are minimal and untested on a real instance.
- Terraform CLI in use (1.16.2) is older than the latest release; not blocking.

## Next phases
5. ALB, target group, launch template (IMDSv2, encrypted EBS, instance profile), Auto Scaling
   group and scaling policy.
6. CloudWatch alarms and SNS notifications; RDS log exports.
7. Optional CloudFront and WAF.
8. `envs/prod` and any modules justified by reuse.
