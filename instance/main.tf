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


# # Security Group for Developer VPC
resource "aws_security_group" "allow_tls" {
  name        = var.security_group_name
  description = var.security_group_des
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  count = length(var.ingress_rules)
  # cidr_ipv4         = var.vpc_main_cidr

  # type        = var.security_group_type
  from_port   = var.ingress_rules[count.index].from_port
  to_port     = var.ingress_rules[count.index].to_port
  ip_protocol    = var.ingress_rules[count.index].protocol
  # cidr_blocks    = var.ingress_rules[count.index].cidr_blocks
  cidr_ipv4 = "0.0.0.0/0" #var.vpc_main_cidr
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_network_interface" "myNic" {
  # count           =  var.nicCount
  subnet_id       =  var.ec2_subnet_id  #module.myapp-subnet.subnet.id
  security_groups = [aws_security_group.allow_tls.id]  #[var.securityGroupId]

  tags = {
    Name = var.network_tags
  }
}

# Instances in Developer VPC
resource "aws_instance" "myec2" {
  # count         = var.instanceCount
  ami           = data.aws_ami.latest_amazon_linux.id     #get the latest AMI which is ami-04e5276ebb8451442" 
  instance_type = var.instance_type
  availability_zone = var.ec2_avail_zone

  # this is how you reference the output object
  # subnet_id     =  var.security_groupId #module.myapp-subnet.subnet.id

  # security_groups = [aws_security_group.allow_tls.id]


#   TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \ 
#   && curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/

  user_data =<<-EOF
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
    device_index         = 0 #count.index
  }


  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo apt-get update"
  #   ]
  # }

  tags = {
     Name = "${var.ec2_seg}-instance"
  }
}