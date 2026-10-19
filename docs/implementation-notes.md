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
modules/          network, security, storage, iam, database
                  (each: main.tf variables.tf outputs.tf versions.tf)
envs/dev/         dev environment: module calls (main.tf) and environment values
  main.tf  moved.tf  variables.tf  locals.tf  outputs.tf  versions.tf  providers.tf
  backend.hcl.example  terraform.tfvars.example
docs/             this documentation
```

## Module refactor (branch `refactor/modules`)
Resources written in phases 2-4 were moved from the `envs/dev` root into five modules. Module
dependencies: `network` -> `security` -> `database`; `storage` and `database` -> `iam`.

- **Behavior:** names, arguments and tags are unchanged; each module receives
  `name_prefix` and builds the same names as before. Verified offline by comparing the
  resource blocks before and after (40 resources in both, no duplicates; the only changed
  lines are `local.`/resource references replaced by module variables).
- **State addresses:** every resource address changes (e.g. `aws_vpc.main` ->
  `module.network.aws_vpc.main`). `envs/dev/moved.tf` has one `moved` block per resource,
  including every `for_each` instance. They are not proof that existing infrastructure is safe.
  If state exists, the first plan must be reviewed to show only moves and no create, change
  or destroy for these resources (not yet run). If nothing was ever applied, the blocks are
  ignored. Remove `moved.tf` after one successful apply.
- **Validation:** kept at the root variables and repeated inside the modules that consume
  them.
- The `iam` module takes the bucket ARN and the DB secret ARN as inputs, so it is created
  after `storage` and `database`.

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

## GitHub Actions
- `.github/workflows/terraform.yml` is the only workflow (it replaced the separate CI and deploy
  workflows). It has four sequential jobs: `init` -> `validate` -> `plan` -> `apply`.
  - Pull requests and pushes to `main` / `refactor/modules` run `validate` only (`init`, `plan`
    and `apply` are skipped), so no AWS credentials are used on those events. The push and pull
    request runs of the same branch share a concurrency group, so the older one is cancelled.
  - Manual runs (`workflow_dispatch`) run `init` -> `validate` -> `plan`. Backend values come
    from the `TF_STATE_BUCKET` and `AWS_REGION` variables and the key `dev/terraform.tfstate`.
- The plan is never printed. The job summary lists creates, updates, destroys, replaces and
  moves by address. A destroy or replace fails the run unless `allow_destroy` is set. The plan
  is fingerprinted (SHA-256, shown in the summary and re-checked by apply). Only when
  `apply=true` it is also encrypted with a key derived from the existing
  `AWS_SECRET_ACCESS_KEY` plus the run id and attempt (no extra secret) and stored as a 1-day
  artifact named per run attempt. It is never uploaded in plaintext.
- **Apply is locked in code** (`false &&` in the apply job's `if`). Unlocked, it would also
  require a manual run, `apply=true`, branch `main`, a matching `expected_state_resources`, and
  approval for the existing `production` environment. Unlock only in a reviewed change after
  the blockers below are resolved. The earlier optional `TF_APPLY_ENABLED` variable was dropped
  in favor of this stricter code lock.
- Init and plan only run for the repository owner on `main` or `refactor/modules`. Missing or
  malformed settings fail the `init` job before any AWS call (names only, never values), an
  unreadable remote state fails closed instead of reporting 0 resources, and a missing or empty
  state fails the plan unless `allow_initial_create` is set.
- Required existing GitHub setup: secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`;
  variables `TF_STATE_BUCKET`, `AWS_REGION`. No other secret or variable is used.
- Open security blockers for enabling apply: the same AWS keys are used by plan and apply (no
  read-only identity, no environment-scoped keys); `main` branch protection and the
  `production` environment (reviewers, prevent self-review) are unverified; the Linux
  provider lock hashes are unverified; the reviewer-check API call is untested.
- Not yet run on GitHub; the workflows were checked locally only (shell syntax, structure).

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
