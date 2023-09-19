# Define the AWS provider
provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

# Define a Virtual Private Cloud (VPC)
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block
}

# Create public and private subnets in separate Availability Zones (AZs)
resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = element(["10.0.3.0/24", "10.0.4.0/24"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
}

# Create an internet gateway for public subnet routing
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Attach the internet gateway to the VPC

resource "aws_internet_gateway_attachment" "my_igw_attachment" {
  internet_gateway_id = aws_internet_gateway.my_igw.id
  vpc_id              = aws_vpc.my_vpc.id
}


# Define a security group for the EC2 instances running Docker
resource "aws_security_group" "my_sg" {
  name        = "my-sg"
  description = "Security group for Dockerized application"

  # Allow incoming SSH traffic from trusted IPs (Update the CIDR block)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["X.X.X.X/32"] # Replace with your trusted IP address
  }

  # Allow incoming HTTP traffic from the load balancer
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow outgoing traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define a security group for the load balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Security group for the load balancer"

  # Allow incoming HTTP traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define an Elastic Load Balancer
resource "aws_lb" "my_lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public_subnets[*].id
  enable_deletion_protection = false # Disable for demo purposes; consider enabling in production
}

# Define a target group for the Load Balancer
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

# Define an Auto Scaling Group for Dockerized instances
resource "aws_launch_template" "my_launch_template" {
  name_prefix   = "my-launch-template-"
  instance_type = "t2.micro" 
  key_name      = "my-key-pair"
  
  
  # User data script for Dockerized application
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -aG docker ec2-user
              # Pull and run the Dockerized application
              sudo docker pull nginxdemos/hello
              sudo docker run -d -p 80:80 nginxdemos/hello
              EOF
}

# Define an Auto Scaling Group for Dockerized instances
resource "aws_autoscaling_group" "my_asg" {
  name                 = "my-asg"
  max_size             = 3
  min_size             = 2
  desired_capacity     = 2
  launch_template {
    id = aws_launch_template.my_launch_template.id
  }
  target_group_arns = [aws_lb_target_group.my_target_group.arn]
  vpc_zone_identifier = aws_subnet.private_subnets[*].id
}

# Outputs
output "load_balancer_dns" {
  value = aws_lb.my_lb.dns_name
}

output "private_key" {
  value       = tls_private_key.my_private_key.private_key_pem
  sensitive   = true
  description = "Private SSH key to access instances securely"
}

# Generate an SSH key pair
resource "tls_private_key" "my_private_key" {
  algorithm = "RSA"
}

# Example: Creating an IAM Role and Instance Profile for EC2 (for service accounts)
resource "aws_iam_role" "my_instance_role" {
  name = "my-instance-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "my_instance_profile" {
  name = "my-instance-profile"
  role = aws_iam_role.my_instance_role.name
}

