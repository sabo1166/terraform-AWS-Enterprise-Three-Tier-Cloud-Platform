# Rules are separate resources so the three groups can reference each other
# without creating a dependency cycle.

# ---------------------------------------------------------------------------
# ALB
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "Public Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from allowed client CIDRs (redirects to HTTPS when enabled)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value

  for_each = toset(var.alb_ingress_cidrs)
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = var.enable_https ? toset(var.alb_ingress_cidrs) : toset([])

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from allowed client CIDRs"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward traffic and health checks to application instances"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.app.id
}

# ---------------------------------------------------------------------------
# Application instances (no SSH, no direct internet ingress)
# ---------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name_prefix = "${var.name}-app-"
  description = "Application instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-app-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "App port from the ALB only"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb.id
}

# Outbound web access is needed to install packages through the NAT Gateway.
resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS out (package repositories via NAT)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_http_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP out (package repositories via NAT)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "MySQL to the database tier"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.db.id
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  description = "RDS MySQL"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-db-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL from the application tier only"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.app.id
}
