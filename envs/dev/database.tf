locals {
  db_identifier = "${local.name_prefix}-mysql"

  # Parameter group family follows the engine version: "8.0.40" -> "mysql8.0".
  db_family = "mysql${join(".", slice(split(".", var.db_engine_version), 0, 2))}"
}

# Places the instance in the two private database subnets (one per AZ). RDS
# needs subnets in at least two AZs even when Multi-AZ is off.
resource "aws_db_subnet_group" "main" {
  name        = "${local.db_identifier}-subnets"
  description = "Private database subnets for ${local.db_identifier}"
  subnet_ids  = [for s in aws_subnet.db : s.id]

  tags = { Name = "${local.db_identifier}-subnets" }
}

resource "aws_db_parameter_group" "main" {
  # name_prefix + create_before_destroy lets a changed group be swapped in
  # without a name clash (a group in use cannot be deleted first).
  name_prefix = "${local.db_identifier}-"
  description = "MySQL parameters for ${local.db_identifier}"
  family      = local.db_family

  # Reject unencrypted client connections.
  parameter {
    name  = "require_secure_transport"
    value = "1"
  }

  # Full Unicode (emoji etc.); the legacy utf8/latin1 defaults are lossy.
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = { Name = "${local.db_identifier}-params" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "main" {
  identifier = local.db_identifier

  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Encrypted at rest with the AWS-managed aws/rds key (no KMS key cost).
  storage_type          = "gp3"
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage == 0 ? null : var.db_max_allocated_storage
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username

  # RDS generates the master password and keeps it in Secrets Manager, so no
  # password exists in the code, variables or plan output. Only the secret ARN
  # (not its value) is recorded in Terraform state.
  manage_master_user_password = true

  # Private placement: db subnets only, no public address, reachable solely
  # from the app tier via the db security group.
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  port                   = var.db_port

  parameter_group_name = aws_db_parameter_group.main.name
  multi_az             = var.db_multi_az

  backup_retention_period    = var.db_backup_retention_days
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true

  # Deletion safety: protected by default, and a final snapshot is taken
  # unless explicitly skipped. The snapshot name is fixed, so a second
  # destroy needs the earlier final snapshot removed or renamed first.
  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${local.db_identifier}-final"

  # Parameter and size changes wait for the maintenance window instead of
  # restarting the database mid-day.
  apply_immediately = false

  tags = { Name = local.db_identifier }
}
