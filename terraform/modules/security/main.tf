#ELB sercurity group and its roles
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "alb-sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1" # means all ip protocols
}

#bastion host sercurity group and its roles
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id

  cidr_ipv4   = var.admin_ip
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


# Frontend securty group 
resource "aws_security_group" "frontend" {
  name        = "frontend-sg"
  description = "Security group for frontend application instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "frontend-sg"
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_ingress_rule" "frontend_http" {
  security_group_id            = aws_security_group.frontend.id
  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "frontend_ssh" {
  security_group_id            = aws_security_group.frontend.id
  referenced_security_group_id = aws_security_group.bastion.id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "frontend_all" {
  security_group_id = aws_security_group.frontend.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#Backend security group
resource "aws_security_group" "backend" {
  name        = "backend-sg"
  description = "Security group for backend API instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "backend-sg"
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_ingress_rule" "backend_api" {
  security_group_id            = aws_security_group.backend.id
  referenced_security_group_id = aws_security_group.internal_alb.id

  from_port   = 3000
  to_port     = 3000
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "backend_ssh" {
  security_group_id            = aws_security_group.backend.id
  referenced_security_group_id = aws_security_group.bastion.id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}


resource "aws_vpc_security_group_egress_rule" "backend_all" {
  security_group_id = aws_security_group.backend.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#internal ALB sg
resource "aws_security_group" "internal_alb" {
  name        = "internal-alb-sg"
  description = "Security group for internal backend ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "internal-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "internal_alb_http" {
  security_group_id            = aws_security_group.internal_alb.id
  referenced_security_group_id = aws_security_group.frontend.id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "internal_alb_all" {
  security_group_id = aws_security_group.internal_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#database security group
resource "aws_security_group" "database" {
  name        = "database-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  tags = {
    Name = "database-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "database_postgresql" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id =  aws_security_group.backend.id
  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}
#Jenkins part
resource "aws_security_group_rule" "jenkins_to_frontend_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"

  source_security_group_id = var.jenkins_security_group_id
  security_group_id        = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "jenkins_to_backend_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"

  source_security_group_id = var.jenkins_security_group_id
  security_group_id        = aws_security_group.backend.id
}

