# Environment composition: wires the reusable modules together. Resource names
# are derived from local.name_prefix, so they are identical to the pre-module
# layout (see moved.tf for the state-address mapping).

module "network" {
  source = "../../modules/network"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  nat_mode    = var.nat_mode
}

module "security" {
  source = "../../modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  alb_ingress_cidrs = var.alb_ingress_cidrs
  app_port          = var.app_port
  db_port           = var.db_port
}

module "storage" {
  source = "../../modules/storage"

  name_prefix = local.name_prefix
}

module "database" {
  source = "../../modules/database"

  name_prefix       = local.name_prefix
  subnet_ids        = values(module.network.db_subnet_ids)
  security_group_id = module.security.db_security_group_id
  db_port           = var.db_port

  db_engine_version        = var.db_engine_version
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_name                  = var.db_name
  db_username              = var.db_username
  db_multi_az              = var.db_multi_az
  db_backup_retention_days = var.db_backup_retention_days
  db_deletion_protection   = var.db_deletion_protection
  db_skip_final_snapshot   = var.db_skip_final_snapshot
}

module "iam" {
  source = "../../modules/iam"

  name_prefix    = local.name_prefix
  app_bucket_arn = module.storage.bucket_arn
  db_secret_arn  = module.database.master_secret_arn
}
