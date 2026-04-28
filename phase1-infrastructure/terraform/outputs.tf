output "server_public_ip" {
  description = "Public ip address to access server via SSH/Website"
  value       = aws_instance.final_devops_server.public_ip
}

output "server_public_dns" {
  description = "Server's public DNS address"
  value       = aws_instance.final_devops_server.public_dns
}
