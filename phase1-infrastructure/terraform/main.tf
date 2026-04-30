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
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "final_devops_server" {
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
    Name = "Final-Devops"
  }
}

resource "aws_eip" "final_devops_eip" {
  instance = aws_instance.final_devops_server.id
  domain   = "vpc"
  tags = {
    Name = "final-devops-static-ip"
  }
}
