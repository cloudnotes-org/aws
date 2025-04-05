# Terraform AWS EC2 Instance Module Documentation

This module provisions an Amazon Linux EC2 instance in a specified VPC subnet with a security group allowing configurable ingress rules and all outbound traffic. It also installs a simple Apache web server via user data.

# Data Sources
aws_ami.latest_amazon_linux

Fetches the latest Amazon Linux 2 AMI from AWS.

data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}


# Security Group

aws_security_group.allow_tls

Creates a security group in the specified VPC.
aws_vpc_security_group_ingress_rule.allow_tls_ipv4

Adds one or more ingress rules to the security group based on a variable list.
aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4

Allows all outbound traffic from the EC2 instance to the internet.


resource "aws_security_group" "allow_tls" { ... }

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" { ... }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" { ... }

# Network Interface

aws_network_interface.myNic

Creates a custom ENI (Elastic Network Interface) that is attached to the EC2 instance. It is associated with the security group created above.

resource "aws_network_interface" "myNic" {
  subnet_id       = var.ec2_subnet_id
  security_groups = [aws_security_group.allow_tls.id]
  tags = {
    Name = var.network_tags
  }
}

# EC2 Instance

aws_instance.myec2

Creates an EC2 instance using:

    The latest Amazon Linux 2 AMI

    A specified instance type and availability zone

    The ENI created earlier

    A user-data script that installs Apache (httpd) and creates a welcome page showing the AWS region

    resource "aws_instance" "myec2" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = var.instance_type
  availability_zone = var.ec2_avail_zone

  user_data = <<-EOF
    #!/bin/bash
    region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
    yum update -y
    yum install -y httpd
    echo "<h4>Hello, from $region</h4>" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
  EOF

  network_interface {
    network_interface_id = aws_network_interface.myNic.id
    device_index         = 0
  }

  tags = {
    Name = "${var.ec2_seg}-instance"
  }
}

# Input Variables
You should define the following input variables for this module to work:

variable "security_group_name" {}
variable "security_group_des" {}
variable "vpc_id" {}
variable "vpc_main_cidr" {} # optional if using static CIDR
variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    # cidr_blocks = list(string) # optional, currently not used
  }))
}
variable "network_tags" {}
variable "ec2_subnet_id" {}
variable "instance_type" {}
variable "ec2_avail_zone" {}
variable "ec2_seg" {}


# Example Usage

module "ec2_instance" {
  source = "./modules/ec2"

  security_group_name = "dev-sg"
  security_group_des  = "Allow web traffic"
  vpc_id              = "vpc-123456789"
  ec2_subnet_id       = "subnet-abc123"
  ec2_avail_zone      = "us-east-1a"
  instance_type       = "t2.micro"
  ec2_seg             = "dev"
  network_tags        = "dev-eni"

  ingress_rules = [
    {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    },
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    }
  ]
}
