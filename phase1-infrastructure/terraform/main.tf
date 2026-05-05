resource "aws_security_group" "final_devops_sg" {
  name        = "final_devops_sg"
  description = "Allow web traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 32000
    to_port     = 32000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "final_devops_server" {
  count         = 2
  ami           = "ami-02dd44faa40720bb8"
  instance_type = "t2.medium"
  key_name      = var.ssh_ec2

  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /home/ubuntu/.ssh
              %{ for key in var.member_public_keys ~}
              echo "${key}" >> /home/ubuntu/.ssh/authorized_keys
              %{ endfor ~}
              chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
              chmod 600 /home/ubuntu/.ssh/authorized_keys
              EOF

  vpc_security_group_ids = [aws_security_group.final_devops_sg.id]

  tags = {
    Name = count.index == 0 ? "Final-DevOps-Master" : "Final-DevOps-Worker"
  }
}

resource "aws_eip" "final_devops_eip" {
  instance = aws_instance.final_devops_server[0].id
  domain   = "vpc"
  tags = {
    Name = "final-devops-static-ip"
  }
}

resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [k3s_master]
    master ansible_host=${aws_eip.final_devops_eip.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/devops-final.pem ansible_python_interpreter=/usr/bin/python3

    [k3s_workers]
    worker-1 ansible_host=${aws_instance.final_devops_server[1].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/devops-final.pem ansible_python_interpreter=/usr/bin/python3
  
    [k3s_cluster:children]
    k3s_master
    k3s_workers
  EOT
  
  filename = "../ansible/inventory/hosts.ini" 
}