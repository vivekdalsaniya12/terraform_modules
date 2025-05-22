variable "instances" {
  description = "MAP for EC2 instances Configuration"
  type = map(object({
    name = string
    ami = string
    instance_type = string
    subnet_id = string
    key_name = string
    security_group_ids = list(string)
    associate_public_ip_address = bool
    tags = map(string)

  }))
}

variable "tags" {
  type = map(string)
  default = {}

}


# variable "instance_type" {
#   description = "instance type"
#   type = string
# }
# variable "ami_id" {
#   description = "ami_id"
#   type = string
# }

# variable "instance_name" {
#   description = "instance name"
#   type = string
# }

# variable "instance_count" {
#   description = "instance count"
#   type = string
#   default = "1"
# }
# variable "vpc_id" {
#   description = "vpc id"
#   type = string
# }
# variable "subnet_id" {
#   description = "subnet id"
#   type = string
  
# }

# variable "security_group_name" {
#   description = "security group name"
#   type = string
  
# }

# variable "ingress_from_port" {
#   description = "ingress from port"
#   type = number
#   default = 22
  
# }

# variable "ingress_to_port" {
#   description = "ingress to port"
#   type = number
#   default = 22
  
# }

# variable "egress_from_port" {
#   description = "egress from port"
#   type = number
#   default = 0
  
# }
# variable "egress_to_port" {
#   description = "egress to port"
#   type = number
#   default = 0
  
# }

# variable "public_ip" {
#   description = "associate public ip address"
#   type = bool
#   default = false
  
# }
# variable "key_name" {
#   description = "key name"
#   type = string
#   default = ""
  
# }
