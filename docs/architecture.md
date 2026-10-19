# Architecture

Source of truth is the Terraform in `bootstrap/` and `envs/dev/`. Labels used below:

- **Configured**: present in the code and accepted by `terraform fmt` / `terraform validate`.
- **Assumed**: reasoned from the code or AWS behavior; not observed in a plan or a deployment.
- **Not built**: planned, no code yet.

Nothing here has been planned or applied against AWS.

## Overview

```
Internet
   |
   v   (Not built: ALB, CloudFront, WAF)
 Public subnets (az1, az2)     IGW route; NAT gateway(s) live here
   |
   v   (Not built: Auto Scaling group)
 Private app subnets (az1, az2)   default route -> NAT; S3 gateway endpoint
   |
   v
 Private db subnets (az1, az2)    local route only (no internet path)
   RDS MySQL (Configured)
```

## Configured

### State backend (`bootstrap/`)
- One S3 bucket for remote state: versioning, SSE-S3, all public access blocked, TLS-only
  policy, 90-day expiry of noncurrent versions, `prevent_destroy`.
- Uses its own local state (chicken-and-egg). `envs/dev` declares an empty `backend "s3" {}`
  block, completed at init time from the git-ignored `backend.hcl` (S3 native locking via
  `use_lockfile`; Terraform >= 1.10 is required).

### Network (`envs/dev/network.tf`, `locals.tf`)
- VPC from `vpc_cidr` (default `10.0.0.0/16`, validated to /16-/18) with DNS support and
  hostnames enabled.
- Exactly two Availability Zones (first two returned by AWS, regular zones only), keyed
  `az1`/`az2` so `for_each` addresses stay stable.
- Six subnets via `cidrsubnet(vpc_cidr, 8, n)`: public 0-1, app 10-11, db 20-21. With the
  default CIDR that is `10.0.0.0/24`, `10.0.1.0/24`, `10.0.10.0/24`, `10.0.11.0/24`,
  `10.0.20.0/24`, `10.0.21.0/24` (derived by calculation, not observed).
- Internet Gateway; one public route table (`0.0.0.0/0` via IGW).
- One app route table per AZ (`0.0.0.0/0` via NAT). One db route table with no routes beyond
  the implicit local route.
- Free S3 gateway endpoint attached to the app route tables.
- Default security group locked down with no rules.

### NAT strategy
`nat_mode` selects:

| Mode | NAT gateways | Trade-off |
|---|---|---|
| `single` (default) | one, in az1 | Cheapest. If az1 fails, app subnets in both AZs lose outbound access. |
| `per_az` | one per AZ | About double the NAT cost; each AZ is independent. |

Switching modes later adds or removes NAT gateways and changes app routes; review the plan.

### Storage (`storage.tf`)
- Private app bucket `<project>-<env>-app-<account-id>-<region>`: public access blocked,
  ACLs disabled, versioning, SSE-S3, TLS-only (and TLS >= 1.2) bucket policy.
- No lifecycle rules; noncurrent versions accumulate until one is added.

### Database (`database.tf`)
- DB subnet group over both private db subnets; parameter group (utf8mb4,
  `require_secure_transport = 1`), family derived from `db_engine_version`.
- MySQL instance: encrypted gp3 storage, not publicly accessible, db security group, master
  password managed by RDS in Secrets Manager.
- Defaults: `db.t4g.micro`, 20 GiB with autoscaling to 100, single-AZ, 7-day backups,
  deletion protection on, final snapshot on delete.

### IAM (`iam.tf`)
EC2 role and instance profile; see [security.md](security.md) for the exact permissions.

## Not built yet
Application Load Balancer, EC2 Auto Scaling group and launch template, CloudWatch alarms
and SNS, CloudFront and WAF, HTTPS (needs a domain and ACM certificate), `envs/prod`.

## Availability trade-offs
- `single` NAT is a single-AZ dependency for outbound traffic.
- `db_multi_az = false` by default: a DB-host or AZ failure means downtime until RDS recovers
  it. Set `true` for production.
- Subnets, routing and (once built) the ALB and ASG span two AZs.

## Assumptions and unresolved items
- **Assumed** the default region `us-east-1`; the account and region have not been confirmed.
- **Assumed** `db.t4g.micro` and MySQL `8.0` are offered in the chosen region.
- **Assumed** the remote state bucket will be applied once before `envs/dev` is initialized.
- Resource counts, prices and plan output have not been observed.
- The empty-by-design `modules/` folder was removed; modules will be introduced when a second
  environment justifies them.
