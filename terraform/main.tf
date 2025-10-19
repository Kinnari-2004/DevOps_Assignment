provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Generate SSH key
resource "tls_private_key" "terraform_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key"
  public_key = tls_private_key.terraform_key.public_key_openssh
}

# Save PEM file locally
resource "local_file" "private_key_pem" {
  content         = tls_private_key.terraform_key.private_key_pem
  filename        = "${path.module}/terraform-key.pem"
  file_permission = "0400"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-1a"
  default_for_az    = true
}

# Security Group - Allow all traffic (as per lab manual pattern)
resource "aws_security_group" "devops_sg" {
  name        = "devops-assignment-sg"
  description = "Security group for DevOps assignment - allows required ports"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Django app
  ingress {
    description = "Django"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Docker Swarm communication
  ingress {
    description = "Docker Swarm"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker Swarm overlay"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker Swarm overlay UDP"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker overlay network"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-assignment-sg"
  }
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Controller Instance (Terraform + Ansible + CI)
resource "aws_instance" "controller" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  subnet_id             = data.aws_subnet.default.id

  tags = {
    Name = "controller"
    Role = "controller"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip git
              EOF
}

# Swarm Manager Instance
resource "aws_instance" "swarm_manager" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  subnet_id             = data.aws_subnet.default.id

  tags = {
    Name = "swarm-manager"
    Role = "manager"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              EOF
}

# Swarm Worker A Instance
resource "aws_instance" "swarm_worker_a" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  subnet_id             = data.aws_subnet.default.id

  tags = {
    Name = "swarm-worker-a"
    Role = "worker"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              EOF
}

# Swarm Worker B Instance
resource "aws_instance" "swarm_worker_b" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  subnet_id             = data.aws_subnet.default.id

  tags = {
    Name = "swarm-worker-b"
    Role = "worker"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              EOF
}

# Elastic IPs
resource "aws_eip" "manager_eip" {
  instance = aws_instance.swarm_manager.id
  domain   = "vpc"

  tags = {
    Name = "manager-eip"
  }
}

resource "aws_eip" "worker_a_eip" {
  instance = aws_instance.swarm_worker_a.id
  domain   = "vpc"

  tags = {
    Name = "worker-a-eip"
  }
}

resource "aws_eip" "worker_b_eip" {
  instance = aws_instance.swarm_worker_b.id
  domain   = "vpc"

  tags = {
    Name = "worker-b-eip"
  }
}

# Outputs
output "controller_public_ip" {
  value       = aws_instance.controller.public_ip
  description = "Public IP of Controller"
}

output "manager_public_ip" {
  value       = aws_eip.manager_eip.public_ip
  description = "Elastic IP of Swarm Manager"
}

output "worker_a_public_ip" {
  value       = aws_eip.worker_a_eip.public_ip
  description = "Elastic IP of Worker A"
}

output "worker_b_public_ip" {
  value       = aws_eip.worker_b_eip.public_ip
  description = "Elastic IP of Worker B"
}

output "manager_private_ip" {
  value       = aws_instance.swarm_manager.private_ip
  description = "Private IP of Swarm Manager"
}

output "ssh_key_path" {
  value       = "${path.module}/terraform-key.pem"
  description = "Path to SSH private key"
}