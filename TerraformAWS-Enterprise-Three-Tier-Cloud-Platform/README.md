# TerraformAWS-Enterprise-Three-Tier-Cloud-Platform

Modular Terraform for a two-AZ, three-tier AWS platform: public Application Load Balancer, private Auto Scaling Nginx tier on Amazon Linux 2023, and a private RDS MySQL database.

> Status: written and statically validated only (`fmt`, `init -backend=false`, `validate`). It has **not** been planned or applied against AWS, and the S3 backend, ACM, Route 53 and RDS behaviour are **unverified**.
> `architecture/architecture.png` has not been generated (no diagram tool was available); use the text diagram below.

## Architecture

```
                        Internet
                           |
                  +--------+--------+
                  |  ALB (HTTP/HTTPS) |   public subnets
                  +----+--------+---+
        AZ-A           |        |           AZ-B
 public  10.0.1.0/24 --+        +-- 10.0.2.0/24   (ALB, NAT GW in AZ-A [or both])
                       |        |
 app     10.0.11.0/24  |  ASG   |  10.0.12.0/24   (Nginx, no public IP, port 80 from ALB only)
                       |        |
 db      10.0.21.0/24  +  RDS   +  10.0.22.0/24   (MySQL 3306 from app SG only, no internet route)
```

- One VPC (default `10.0.0.0/16`), exactly two AZs chosen dynamically from the region.
- Public subnets route to the Internet Gateway. App subnets route outbound through NAT. DB subnets have **no** internet route.
- Security groups reference each other (ALB -> app -> DB); no SSH or MySQL is exposed to the internet.

## Modules

| Module | Responsibility |
|---|---|
| `networking` | VPC, 6 subnets, IGW, NAT Gateway(s), route tables |
| `security` | ALB / app / DB security groups and rules |
| `acm` | DNS-validated certificate (only if `domain_name` is set) |
| `route53` | Alias record in an **existing** hosted zone (optional) |
| `alb` | ALB, target group + health check, listeners |
| `application` | AL2023 Launch Template, Nginx user data, ASG, CPU target-tracking policy, optional SSM role |
| `database` | DB subnet group and RDS MySQL |

## AWS resources and purpose

VPC, subnets, route tables, IGW (network); EIP + NAT Gateway (private egress to install Nginx); 3 security groups (least privilege); ALB, target group, listeners (entry point); ACM certificate and validation (TLS, optional); Route 53 records (optional); Launch Template, ASG, scaling policy (app tier); optional IAM role/profile (SSM access, off by default); DB subnet group and RDS MySQL (data tier).

## Requirements

- Terraform `>= 1.10` (needed for `use_lockfile`), AWS provider `~> 5.0`, Windows PowerShell 5.1 or PowerShell 7, AWS CLI (optional).
- AWS credentials able to create the resources above (EC2/VPC, ELBv2, AutoScaling, RDS, IAM role creation if `enable_ssm`, ACM and Route 53 if used) and read/write the state bucket.

## State backend

`environments/dev/backend.tf` uses the **existing** bucket `states.tf-2026-test-1`, key `enterprise-three-tier/dev/terraform.tfstate`, `encrypt = true`, `use_lockfile = true` (no DynamoDB). The project does not create the bucket; it must already exist and ideally have versioning enabled.

**Bucket region.** An unauthenticated HEAD request to S3 returned `403` with `x-amz-bucket-region: us-east-1`, so a bucket with this name exists in `us-east-1`. That does not prove the bucket belongs to your account, and your access to it is unverified. Confirm with valid credentials:

```powershell
aws sts get-caller-identity                                   # shows account/ARN only, no secrets
aws s3api get-bucket-location --bucket states.tf-2026-test-1  # null/"None" means us-east-1
aws s3api head-bucket --bucket states.tf-2026-test-1          # exit 0 = exists and you may access it
aws s3api get-bucket-versioning --bucket states.tf-2026-test-1
```

If it differs, edit `region` in `backend.tf` or run `terraform init -backend-config="region=<bucket-region>"`. Credentials are never stored in the backend block. If the bucket already holds state under this key, inspect and back it up before any `init`.

### Verifying AWS credentials (Windows PowerShell)

After correcting credentials (`aws configure`, `aws configure sso`, or environment variables you set yourself), check which identity is active without printing secrets:

```powershell
aws configure list-profiles
aws sts get-caller-identity                      # default profile
aws sts get-caller-identity --profile dev_profile
$env:AWS_PROFILE = "dev_profile"                 # pick the profile Terraform should use
```

`InvalidClientTokenId` usually means a wrong, expired, or revoked key or session token, or stale `AWS_*` environment variables overriding the profile.

## Variables and secrets

Copy `environments/dev/terraform.tfvars.example` to `terraform.tfvars` (git-ignored) and edit non-secret values.

The database password is sensitive and must not go in files:

```powershell
$env:TF_VAR_db_password = Read-Host "DB password" -MaskInput   # PowerShell 7
# Windows PowerShell 5.1: $env:TF_VAR_db_password = "<type it>"  (avoid saving it in shell history files)
```

Alternative: `db_manage_master_user_password = true` lets RDS keep the password in Secrets Manager (not in state; small extra cost). Note that a supplied password is stored in Terraform state, so protect the state bucket.

## HTTPS, domain and Route 53

- **No domain** (`domain_name = ""`): no certificate and no HTTPS listener. You must set `allow_http_only = true` explicitly, otherwise the plan fails. Traffic is **plain HTTP and unencrypted**; use for development only. Reach the site via the `application_url` output.
- **With a domain**: set `domain_name`. An ACM certificate (DNS validation) is created in the same region as the ALB, the ALB gets an HTTPS listener, and port 80 redirects to 443.
  - With `hosted_zone_id` (an **existing** public zone containing the domain): validation CNAMEs and the alias record are created automatically.
  - Without `hosted_zone_id`: `apply` waits (up to 45 min) for you to create the CNAME records shown in the `certificate_domain_validation_options` output at your DNS provider, and no alias record is created.
- Prerequisites: you own the domain and its DNS is served by the hosted zone. This project never registers domains or creates hosted zones.

## Cost warnings

These resources are billable while they exist:
- **NAT Gateway**: hourly charge plus per-GB processing. Default `nat_gateway_mode = "single"` (one NAT in AZ-A, cheaper, but an AZ-A failure removes outbound access for both AZs). `"per_az"` gives one NAT per AZ, roughly double the NAT cost.
- **Application Load Balancer**: hourly plus LCU charges.
- **RDS MySQL**: instance, storage, and backups. **Multi-AZ** (`db_multi_az = true`) improves availability but roughly doubles the instance cost; it is off by default.
- Two `t3.micro` instances (the default minimum) plus EBS volumes; Elastic IPs for NAT.

## Commands (Windows PowerShell)

Run from the project root.

```powershell
# Offline checks: fmt -check, init -backend=false, validate (no AWS calls)
.\scripts\validate.ps1

# Or manually
terraform fmt -recursive
terraform -chdir=environments/dev init            # uses the S3 backend; needs credentials
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev plan -out=dev.tfplan

# Init + validate + plan in one go (never applies)
.\scripts\deploy.ps1
```

### Reviewing the plan before approval

```powershell
terraform -chdir=environments/dev show dev.tfplan
```

Check: the add/change/destroy counts; no `-/+` replacements or destroys you did not expect; subnet CIDRs and the two AZs; one NAT Gateway (or two); security group sources are SG references, not `0.0.0.0/0`, apart from ALB 80/443; `publicly_accessible = false`; `multi_az` as intended; no secrets exposed. Plan files can contain sensitive data: never commit them.

### Deploy (human decision)

Only after reviewing the plan: `.\scripts\deploy.ps1 -Apply` (asks you to type `apply`, then applies the saved plan), or `terraform -chdir=environments/dev apply dev.tfplan`.

## Cleanup

1. Back up anything you need from the database. By default a final snapshot (`<name>-mysql-final`) is taken on destroy; `db_skip_final_snapshot = true` makes deletion unrecoverable. If `db_deletion_protection = true`, disable it first.
2. `terraform -chdir=environments/dev plan -destroy` and review it. Then `terraform -chdir=environments/dev destroy` (billing stops only after resources are gone).
3. **Never delete the state object or bucket before destroying**: Terraform would lose track of live resources. The state bucket is not managed by this project and is not removed by `destroy`.
4. A second destroy of the same database fails if the earlier final snapshot still exists; delete or rename that snapshot.

## Troubleshooting

User data logs to `/var/log/user-data.log` (also `/var/log/cloud-init-output.log`). Instances have no SSH; set `enable_ssm = true` for Session Manager access. Targets unhealthy right after launch is normal for up to the 300 s grace period; persistent failure usually means no NAT egress (Nginx install failed).
