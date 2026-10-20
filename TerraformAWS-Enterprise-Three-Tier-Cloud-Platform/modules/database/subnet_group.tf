resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db-subnet-group"
  description = "Private database subnets across two AZs"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.name}-db-subnet-group" })
}
