variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "admin_ip" {
  description = "Public IPv4 address allowed to SSH to the bastion"
  type        = string
}