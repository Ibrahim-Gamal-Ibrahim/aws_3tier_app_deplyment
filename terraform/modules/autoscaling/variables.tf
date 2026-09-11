variable "name" {
  description = "Name prefix for the launch template and ASG"
  type        = string
}

variable "role" {
  description = "Role tag for instances"
  type        = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "private_subnet_a_id" {
  type = string
}

variable "private_subnet_b_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "user_data" {
  description = "Bootstrap script for EC2 instances"
  type        = string
}

variable "min_size" {
  type    = number
  default = 2
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "cpu_target_value" {
  type    = number
  default = 50
}