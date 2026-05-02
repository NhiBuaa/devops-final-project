output "final_devops_master_static_ip" {
  value = aws_eip.final_devops_eip.public_ip
  description = "The static IP address used to configure DNS for the Master"
}

output "all_server_public_ips" {
  value = aws_instance.final_devops_server[*].public_ip
  description = "List of public IPs of all nodes in the cluster"
}

output "all_server_public_dns" {
  value = aws_instance.final_devops_server[*].public_dns

  description = "List of Public DNS of all nodes"
}