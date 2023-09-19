# terraform-deployment-to-host-a-stateless-application
from Image - docker pull nginxdemos/hello

This is covered under several steps commented line in main.tf file also explains about that.
basic steps can be fetched from bellow.

create a VPC with public and private subnets.
An internet gateway is attached to the VPC for public subnet routing.
Security groups are defined for EC2 instances and the load balancer.
An Elastic Load Balancer is created to distribute traffic across Dockerized instances.
An Auto Scaling Group manages the Dockerized instances for HA.
A Launch Template specifies the Dockerized instance configuration and user data script.
Outputs provide the load balancer DNS name and an SSH private key.
An SSH key pair is generated for secure access to instances.
An IAM Role and Instance Profile are created for EC2 instances (for service accounts).
