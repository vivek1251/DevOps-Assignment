provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "devops_sg" {
  name        = "devops-chat-sg"
  description = "Security group for DevOps chat app"

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
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-chat-sg"
  }
}

resource "aws_instance" "devops_server" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t3.micro"
  key_name               = "devops-key"
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  user_data = <<-USERDATA
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose git
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
    git clone https://github.com/vivek1251/DevOps-Assignment.git /home/ubuntu/devops
    cd /home/ubuntu/devops
    docker-compose up -d --build
  USERDATA

  tags = {
    Name = "devops-chat-server"
  }
}

output "public_ip" {
  value       = aws_instance.devops_server.public_ip
  description = "Public IP of the EC2 instance"
}
