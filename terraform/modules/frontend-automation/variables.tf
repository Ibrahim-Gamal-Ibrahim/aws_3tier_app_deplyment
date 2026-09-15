variable "vpc_id" {
  type = string
}

variable "private_subnet_a_id" {
  type = string
}

variable "private_subnet_b_id" {
  type = string
}

variable "jenkins_security_group_id" {
  type = string
}

variable "jenkins_private_ip" {
  type = string
}

variable "jenkins_job_name" {
  type = string
}

variable "jenkins_user" {
  type = string
}

variable "jenkins_api_token" {
  type      = string
  sensitive = true
}

variable "frontend_asg_name" {
  type = string
}

variable "frontend_lifecycle_hook_name" {
  type = string
}
