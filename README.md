# terraform-deployment-to-host-a-stateless-application
from Image - docker pull nginxdemos/hello

This is covered under several steps commented line in main.tf file also explains about that.
basic steps can be fetched from bellow.

1.create a VPC with public and private subnets.
2.An internet gateway is attached to the VPC for public subnet routing.
3.Security groups are defined for EC2 instances and the load balancer.
4.An Elastic Load Balancer is created to distribute traffic across Dockerized instances.
5.An Auto Scaling Group manages the Dockerized instances for HA.
6.A Launch Template specifies the Dockerized instance configuration and user data script.
7.Outputs provide the load balancer DNS name and an SSH private key.
8.An SSH key pair is generated for secure access to instances.
9.An IAM Role and Instance Profile are created for EC2 instances (for service accounts).
