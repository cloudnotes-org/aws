#Instance and Nic Card variable
variable  instance_type {}
# variable  instanceCount {}
# variable  nicCount {}
variable  myregion {}
# variable  ec2Userdata {}
variable  ec2_subnet_id {}
# variable  securityGroupId {}
# variable  securityGroup_name {}

variable ec2_avail_zone {}
variable ec2_seg {}

variable security_group_name {}

# variable vpc_main_cidr{}  # aws_vpc.main.cidr_block
variable security_group_type {
    type = string
    default = "ingress"
}  

# # sg_ingress/main.tf
variable "security_group_des" {}

variable "ingress_rules" {
  description = "A list of ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable vpc_id{}
variable vpc_main_cidr{}  # aws_vpc.main.cidr_block


variable network_tags {}