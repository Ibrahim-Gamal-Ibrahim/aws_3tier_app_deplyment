output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_private_ip" {
  value = aws_instance.jenkins.private_ip
}

output "jenkins_security_group_id" {
  value = aws_security_group.jenkins.id
}

output "jenkins_role_name" {
  value = aws_iam_role.jenkins.name
}
