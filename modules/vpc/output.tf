output "vpc_id" {
  value = aws_vpc.this.id
}

# output "public_subnet_ids" {
#   value = aws_subnet.public[*].id
# }

output "public_subnet_ids" {
  value = {
    for subnet_key , sn in aws_subnet.public : var.public_subnet_cidrs[subnet_key] => sn.id
  }
}

# output "private_subnet_ids" {
#   value = aws_subnet.private[*].id
# }

output "private_subnet_ids" {
  value = {
    for subnet_key , sn in aws_subnet.private : var.private_subnet_cidrs[subnet_key] => sn.id
  }
  
}

output "nat_gateway_id" {
  value = aws_nat_gateway.this[*].id
}

output "security_group_ids" {
  value = {
    for sg_key, sg in aws_security_group.custom : sg_key => sg.id
  }
}