variable "name" {
  type    = string
  default = "jenkins"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type = string
}

variable "admin_cidr" {
  description = "Your public IP in CIDR notation"
  type        = string
}
