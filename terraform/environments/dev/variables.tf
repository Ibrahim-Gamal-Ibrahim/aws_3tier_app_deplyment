variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet A"
  type        = string
  default     = "10.0.11.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet B"
  type        = string
  default     = "10.0.12.0/24"
}

variable "db_subnet_a_cidr" {
  description = "CIDR block for database subnet A"
  type        = string
  default     = "10.0.21.0/24"
}

variable "db_subnet_b_cidr" {
  description = "CIDR block for database subnet B"
  type        = string
  default     = "10.0.22.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}


variable "admin_ip" {
  description = "Public IPv4 address allowed to SSH to bastion"
  type        = string
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "app_subdomain" {
  description = "Application subdomain"
  type        = string
  default     = "app"
}

variable "alert_email" {
  description = "Email address for infrastructure notifications"
  type        = string
}

variable "db_name" {
  description = "Application database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "jenkins_user" {
  type = string
}

variable "jenkins_api_token" {
  type      = string
  sensitive = true
}