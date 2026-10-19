# Security

Labels: **Configured** (in code, passes `validate`), **Assumed** (reasoned, not observed),
**Open** (unresolved risk). Nothing has been deployed or tested against AWS.

## Network exposure
**Configured**
- Only the ALB security group is intended to face the internet, on TCP 80 from
  `alb_ingress_cidrs` (default `0.0.0.0/0`). The ALB itself is not built yet.
- App and database subnets are private. Database subnets have no internet route in either
  direction; the database instance has `publicly_accessible = false`.
- The default VPC security group has no rules.

## Security group chain

| Group | Ingress | Egress |
|---|---|---|
| alb | TCP 80 from `alb_ingress_cidrs` | `app_port` to app SG |
| app | `app_port` from ALB SG | TCP 443 to `0.0.0.0/0` (via NAT); `db_port` to db SG |
| db | `db_port` from app SG | none |

Tier-to-tier rules reference security groups, not CIDRs. The app tier's HTTPS egress to
anywhere is needed for package repositories, Session Manager and AWS APIs.

## Encryption
**Configured**
- RDS storage encrypted at rest (AWS-managed `aws/rds` key).
- RDS requires TLS (`require_secure_transport = 1`); clients must connect with TLS.
- S3 buckets: SSE-S3, with bucket policies denying non-TLS requests and TLS older than 1.2.
- **Open:** the ALB is HTTP-only for now, so client traffic to the load balancer is not
  encrypted. HTTPS needs a domain and an ACM certificate.
- **Open:** EBS volume encryption and IMDSv2 will be configured with the launch template
  (not built yet).

## IAM (EC2 role `<project>-<env>-app-ec2-role`)
**Configured**: trusted only by `ec2.amazonaws.com`; no managed policies, no admin access;
three inline policies:

| Policy | Allows | Resource |
|---|---|---|
| `ssm-session-manager` | `ssm:UpdateInstanceInformation`, `ssmmessages:CreateControlChannel`, `CreateDataChannel`, `OpenControlChannel`, `OpenDataChannel` | `*` (these actions cannot be resource-scoped) |
| `app-bucket-access` | `s3:ListBucket` | the app bucket |
| | `s3:GetObject`, `s3:PutObject` | objects in the app bucket |
| `db-master-secret-read` | `secretsmanager:GetSecretValue`, `DescribeSecret` | the exact ARN of the RDS-managed secret |

The only wildcard resource is in the Session Manager policy.

**Assumed / Open**
- The Session Manager policy is the minimal set AWS documents; it has not been tested on a
  running instance. If instances fail to register, Run Command style permissions may be
  needed.
- The secret uses the default `aws/secretsmanager` key, so no explicit KMS permission is
  granted. If a customer-managed key is adopted later, add `kms:Decrypt` scoped to it.

## Secrets handling
**Configured**
- No passwords, keys or credentials in the code or variables. The RDS master password is
  generated and stored by RDS (`manage_master_user_password = true`).
- Outputs expose only the secret's ARN, never its value.
- `.gitignore` excludes state, saved plans, real `*.tfvars`, `backend*.hcl` and `.env` /
  `*.pem`.

**Open**
- Terraform state contains resource attributes including the secret ARN and other
  identifiers. Treat state as sensitive; the state bucket is private, versioned and
  encrypted, but access to it is not yet restricted by a bucket policy beyond TLS.
- The state bucket uses SSE-S3 rather than a customer-managed KMS key.

## Deletion protection
**Configured**: RDS deletion protection on by default with a final snapshot; the state bucket
has `prevent_destroy`; the app bucket has no `force_destroy`.

## Not yet covered
VPC flow logs, WAF and CloudFront, CloudWatch alarms, CloudTrail, GuardDuty, a customer-managed
KMS key and the account-level baseline are outside the current code.
