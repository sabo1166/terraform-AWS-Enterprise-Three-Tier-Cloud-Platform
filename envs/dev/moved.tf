# State-address migration for the move of resources into modules.
#
# Each block maps a former root address to its module address. A moved block
# on a for_each resource covers every instance (e.g. aws_subnet.public["az1"]
# -> module.network.aws_subnet.public["az1"]). If no state exists for the old
# address (nothing was ever applied), the blocks are ignored.
#
# These blocks only RECORD the intended rename; Terraform applies it when a
# plan/apply runs against real state. Review that plan: it should show the
# resources "to move" and 0 to add / 0 to change / 0 to destroy for them.
# Remove this file after one successful apply of the new layout.

# --- network ----------------------------------------------------------------
moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_default_security_group.default
  to   = module.network.aws_default_security_group.default
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_subnet.app
  to   = module.network.aws_subnet.app
}

moved {
  from = aws_subnet.db
  to   = module.network.aws_subnet.db
}

moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table.app
  to   = module.network.aws_route_table.app
}

moved {
  from = aws_route_table.db
  to   = module.network.aws_route_table.db
}

moved {
  from = aws_route.public_internet
  to   = module.network.aws_route.public_internet
}

moved {
  from = aws_route.app_nat
  to   = module.network.aws_route.app_nat
}

moved {
  from = aws_route_table_association.public
  to   = module.network.aws_route_table_association.public
}

moved {
  from = aws_route_table_association.app
  to   = module.network.aws_route_table_association.app
}

moved {
  from = aws_route_table_association.db
  to   = module.network.aws_route_table_association.db
}

moved {
  from = aws_eip.nat
  to   = module.network.aws_eip.nat
}

moved {
  from = aws_nat_gateway.main
  to   = module.network.aws_nat_gateway.main
}

moved {
  from = aws_vpc_endpoint.s3
  to   = module.network.aws_vpc_endpoint.s3
}

# --- security ---------------------------------------------------------------
moved {
  from = aws_security_group.alb
  to   = module.security.aws_security_group.alb
}

moved {
  from = aws_security_group.app
  to   = module.security.aws_security_group.app
}

moved {
  from = aws_security_group.db
  to   = module.security.aws_security_group.db
}

moved {
  from = aws_vpc_security_group_ingress_rule.alb_http
  to   = module.security.aws_vpc_security_group_ingress_rule.alb_http
}

moved {
  from = aws_vpc_security_group_egress_rule.alb_to_app
  to   = module.security.aws_vpc_security_group_egress_rule.alb_to_app
}

moved {
  from = aws_vpc_security_group_ingress_rule.app_from_alb
  to   = module.security.aws_vpc_security_group_ingress_rule.app_from_alb
}

moved {
  from = aws_vpc_security_group_egress_rule.app_https_out
  to   = module.security.aws_vpc_security_group_egress_rule.app_https_out
}

moved {
  from = aws_vpc_security_group_egress_rule.app_to_db
  to   = module.security.aws_vpc_security_group_egress_rule.app_to_db
}

moved {
  from = aws_vpc_security_group_ingress_rule.db_from_app
  to   = module.security.aws_vpc_security_group_ingress_rule.db_from_app
}

# --- storage ----------------------------------------------------------------
moved {
  from = aws_s3_bucket.app
  to   = module.storage.aws_s3_bucket.app
}

moved {
  from = aws_s3_bucket_ownership_controls.app
  to   = module.storage.aws_s3_bucket_ownership_controls.app
}

moved {
  from = aws_s3_bucket_public_access_block.app
  to   = module.storage.aws_s3_bucket_public_access_block.app
}

moved {
  from = aws_s3_bucket_versioning.app
  to   = module.storage.aws_s3_bucket_versioning.app
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.app
  to   = module.storage.aws_s3_bucket_server_side_encryption_configuration.app
}

moved {
  from = aws_s3_bucket_policy.app
  to   = module.storage.aws_s3_bucket_policy.app
}

# --- iam --------------------------------------------------------------------
moved {
  from = aws_iam_role.app
  to   = module.iam.aws_iam_role.app
}

moved {
  from = aws_iam_instance_profile.app
  to   = module.iam.aws_iam_instance_profile.app
}

moved {
  from = aws_iam_role_policy.ssm_session
  to   = module.iam.aws_iam_role_policy.ssm_session
}

moved {
  from = aws_iam_role_policy.app_bucket_access
  to   = module.iam.aws_iam_role_policy.app_bucket_access
}

moved {
  from = aws_iam_role_policy.db_secret_read
  to   = module.iam.aws_iam_role_policy.db_secret_read
}

# --- database ---------------------------------------------------------------
moved {
  from = aws_db_subnet_group.main
  to   = module.database.aws_db_subnet_group.main
}

moved {
  from = aws_db_parameter_group.main
  to   = module.database.aws_db_parameter_group.main
}

moved {
  from = aws_db_instance.main
  to   = module.database.aws_db_instance.main
}
