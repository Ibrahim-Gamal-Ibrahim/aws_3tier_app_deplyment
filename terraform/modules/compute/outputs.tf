output "bastion_id" {
  value = aws_instance.bastion.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "ubuntu_ami_id" {
  value = data.aws_ami.ubuntu.id
}

output "key_name" {
  value = aws_key_pair.main.key_name
}