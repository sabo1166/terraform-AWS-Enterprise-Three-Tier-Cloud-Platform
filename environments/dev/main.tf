locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Known at plan time (unlike the certificate ARN), so it is safe to use for count.
  https_enabled = var.domain_name != ""
}

module "networking" {
  source = "../../modules/networking"

  name                     = local.name
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  enable_nat_gateway       = var.enable_nat_gateway
  nat_gateway_mode         = var.nat_gateway_mode
  tags                     = local.tags
}

module "security" {
  source = "../../modules/security"

  name              = local.name
  vpc_id            = module.networking.vpc_id
  enable_https      = local.https_enabled
  alb_ingress_cidrs = var.alb_ingress_cidrs
  tags              = local.tags
}

module "acm" {
  source = "../../modules/acm"

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  hosted_zone_id            = var.hosted_zone_id
  tags                      = local.tags
}

module "alb" {
  source = "../../modules/alb"

  name                       = local.name
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  security_group_id          = module.security.alb_security_group_id
  enable_https               = local.https_enabled
  certificate_arn            = module.acm.certificate_arn
  allow_http_only            = var.allow_http_only
  enable_deletion_protection = var.alb_deletion_protection
  tags                       = local.tags
}

module "route53" {
  source = "../../modules/route53"

  hosted_zone_id = var.hosted_zone_id
  record_name    = var.domain_name
  alb_dns_name   = module.alb.alb_dns_name
  alb_zone_id    = module.alb.alb_zone_id
}

module "application" {
  source = "../../modules/application"

  name               = local.name
  private_subnet_ids = module.networking.private_app_subnet_ids
  security_group_id  = module.security.app_security_group_id
  target_group_arn   = module.alb.target_group_arn
  instance_type      = var.instance_type
  min_size           = var.asg_min_size
  desired_capacity   = var.asg_desired_capacity
  max_size           = var.asg_max_size
  enable_ssm         = var.enable_ssm
  tags               = local.tags

  # Instances install Nginx through the NAT Gateway, so it must be routable first.
  depends_on = [module.networking]
}

module "database" {
  source = "../../modules/database"

  name                        = local.name
  subnet_ids                  = module.networking.private_db_subnet_ids
  security_group_id           = module.security.db_security_group_id
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password
  manage_master_user_password = var.db_manage_master_user_password
  multi_az                    = var.db_multi_az
  backup_retention_period     = var.db_backup_retention_period
  deletion_protection         = var.db_deletion_protection
  skip_final_snapshot         = var.db_skip_final_snapshot
  tags                        = local.tags
}
