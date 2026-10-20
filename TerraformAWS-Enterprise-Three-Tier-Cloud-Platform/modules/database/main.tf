resource "aws_db_instance" "this" {
  identifier = "${var.name}-mysql"

  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.username
  # Either a caller-supplied (sensitive) password, or RDS-managed in Secrets Manager.
  password                    = var.manage_master_user_password ? null : var.password
  manage_master_user_password = var.manage_master_user_password ? true : null

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az # improves availability; roughly doubles instance cost

  backup_retention_period    = var.backup_retention_period
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-mysql-final"

  tags = merge(var.tags, { Name = "${var.name}-mysql" })

  lifecycle {
    precondition {
      condition     = var.manage_master_user_password || var.password != null
      error_message = "Provide db_password (sensitive, e.g. via TF_VAR_db_password) or set manage_master_user_password = true."
    }
  }
}
