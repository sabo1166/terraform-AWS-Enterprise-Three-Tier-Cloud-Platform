# AWS Enterprise Three-Tier Cloud Platform

Terraform for a three-tier AWS platform: public load balancer tier, private EC2 application
tier, and private RDS MySQL, across two Availability Zones. Built in reviewed phases.

> **Status:** configuration for phases 1-4 is written and passes `terraform fmt` and
> `terraform validate`. Nothing has been planned or applied against AWS.

## Phases

| Phase | Scope | State |
|---|---|---|
| 1 | Remote state bootstrap, repo foundation | Written, validated offline |
| 2 | VPC, subnets, routing, NAT, security groups | Written, validated offline |
| 3 | Private S3 app bucket, EC2 IAM role | Written, validated offline |
| 4 | Private encrypted RDS MySQL | Written, validated offline |
| 5+ | ALB, EC2 Auto Scaling, monitoring, optional CloudFront/WAF | Not started |

## Layout

```
bootstrap/    S3 bucket for remote state (own local state, applied once)
modules/      Reusable modules (each: main.tf variables.tf outputs.tf versions.tf)
  network/  security/  storage/  iam/  database/
envs/dev/     Dev environment: module calls and environment values
  main.tf  moved.tf  variables.tf  locals.tf  outputs.tf  versions.tf  providers.tf
  backend.hcl.example  terraform.tfvars.example
docs/         architecture.md  security.md  implementation-notes.md
```

## Documentation
- [Architecture](docs/architecture.md): tiers, network, NAT trade-offs, what is not built.
- [Security](docs/security.md): security groups, encryption, IAM scope, secrets, open risks.
- [Implementation notes](docs/implementation-notes.md): phase log, cost drivers,
  operating notes, unresolved risks.

## Usage (not yet run)

State bucket first. This needs AWS credentials; review the plan before any apply.

```powershell
cd bootstrap
terraform init
terraform plan
```

Then the environment:

```powershell
cd envs/dev
copy backend.hcl.example backend.hcl            # fill in the bucket name
copy terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan
```

Offline checks (no AWS contact):

```powershell
terraform fmt -check -recursive
cd envs/dev; terraform init -backend=false; terraform validate
```

State, saved plans, `terraform.tfvars`, `backend*.hcl` and credentials are git-ignored and
must never be committed.
