variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet A"
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet B"
  type        = string
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