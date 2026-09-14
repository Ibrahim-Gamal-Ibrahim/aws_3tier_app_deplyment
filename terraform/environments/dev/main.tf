module "networking" {
  source = "../../modules/networking"

  vpc_cidr = var.vpc_cidr

  public_subnet_a_cidr  = var.public_subnet_a_cidr
  public_subnet_b_cidr  = var.public_subnet_b_cidr
  private_subnet_a_cidr = var.private_subnet_a_cidr
  private_subnet_b_cidr = var.private_subnet_b_cidr
  db_subnet_a_cidr      = var.db_subnet_a_cidr
  db_subnet_b_cidr      = var.db_subnet_b_cidr
}

module "security" {
  source = "../../modules/security"

  vpc_id   = module.networking.vpc_id
  admin_ip = var.admin_ip

  jenkins_security_group_id = module.jenkins.jenkins_security_group_id
}


module "compute" {
  source = "../../modules/compute"

  instance_type = var.instance_type

  public_subnet_a_id  = module.networking.public_subnet_a_id
  private_subnet_a_id = module.networking.private_subnet_a_id
  private_subnet_b_id = module.networking.private_subnet_b_id

  bastion_sg_id = module.security.bastion_sg_id


  public_key = file("~/.ssh/terra-devops.pub")
}


module "alb" {
  source = "../../modules/alb"

  vpc_id = module.networking.vpc_id

  public_subnet_a_id = module.networking.public_subnet_a_id
  public_subnet_b_id = module.networking.public_subnet_b_id

  alb_sg_id = module.security.alb_sg_id


  domain_name   = var.domain_name
  app_subdomain = var.app_subdomain
}

module "backend_alb" {
  source = "../../modules/backend-alb"

  vpc_id = module.networking.vpc_id

  private_subnet_a_id = module.networking.private_subnet_a_id
  private_subnet_b_id = module.networking.private_subnet_b_id

  internal_alb_sg_id = module.security.internal_alb_sg_id
}

module "frontend_asg" {
  source = "../../modules/autoscaling"

  name = "frontend"
  role = "frontend"

  ami_id        = module.compute.ubuntu_ami_id
  instance_type = var.instance_type
  key_name      = module.compute.key_name

  security_group_id = module.security.frontend_sg_id

  private_subnet_a_id = module.networking.private_subnet_a_id
  private_subnet_b_id = module.networking.private_subnet_b_id

  target_group_arn = module.alb.target_group_arn

  user_data = local.frontend_user_data

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  cpu_target_value = 50
}

module "backend_asg" {
  source = "../../modules/autoscaling"

  name = "backend"
  role = "backend"

  ami_id        = module.compute.ubuntu_ami_id
  instance_type = var.instance_type
  key_name      = module.compute.key_name

  security_group_id = module.security.backend_sg_id

  private_subnet_a_id = module.networking.private_subnet_a_id
  private_subnet_b_id = module.networking.private_subnet_b_id

  target_group_arn = module.backend_alb.target_group_arn

  user_data = local.backend_user_data

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  cpu_target_value = 50
}


module "monitoring" {
  source = "../../modules/monitoring"

  alert_email = var.alert_email

  frontend_asg_name = module.frontend_asg.asg_name
  backend_asg_name  = module.backend_asg.asg_name

  frontend_alb_arn_suffix = module.alb.alb_arn_suffix

  frontend_target_group_arn_suffix = module.alb.target_group_arn_suffix

  backend_alb_arn_suffix = module.backend_alb.alb_arn_suffix

  backend_target_group_arn_suffix = module.backend_alb.target_group_arn_suffix

  db_instance_identifier = module.database.db_instance_identifier
}

module "database" {
  source = "../../modules/database"

  db_subnet_a_id = module.networking.db_subnet_a_id
  db_subnet_b_id = module.networking.db_subnet_b_id

  database_sg_id = module.security.database_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  db_instance_class = "db.t3.micro"
  allocated_storage = 20
}

module "jenkins" {
  source = "../../modules/jenkins"

  name             = "jenkins"
  vpc_id           = module.networking.vpc_id
  public_subnet_id = module.networking.public_subnet_a_id

  ami_id        = module.compute.ubuntu_ami_id
  instance_type = "t3.small"
  key_name      = "terra-key"

  admin_cidr = var.admin_ip
}

resource "aws_autoscaling_lifecycle_hook" "backend_configuration" {
  name                   = "backend-configuration-hook"
  autoscaling_group_name = module.backend_asg.asg_name

  lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

  heartbeat_timeout = 900
  default_result    = "CONTINUE"
}