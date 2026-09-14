output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "HTTPS URL of the application"
  value       = module.alb.application_url
}

output "bastion_id" {
  value = module.compute.bastion_id
}

output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}
output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_port" {
  value = module.database.db_port
}

output "jenkins_public_ip" {
  value = module.jenkins.jenkins_public_ip
}