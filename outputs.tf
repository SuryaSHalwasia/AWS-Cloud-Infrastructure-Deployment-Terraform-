output "bastion_host_ip" {
    value = aws_instance.mtc_bastion_host_node.public_ip
}

output "private_host_ip" {
    value = aws_instance.mtc_private_node.public_ip
}