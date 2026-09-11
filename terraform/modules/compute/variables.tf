variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "public_subnet_a_id" {
  description = "Public subnet ID for bastion"
  type        = string
}

variable "private_subnet_a_id" {
  description = "Private subnet A ID"
  type        = string
}

variable "private_subnet_b_id" {
  description = "Private subnet B ID"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for bastion"
  type        = string
}


variable "public_key" {
  description = "Public SSH key"
  type        = string
}