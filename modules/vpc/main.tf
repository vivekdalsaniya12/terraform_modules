resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = element(aws_subnet.public[*].id, 0)
  tags = {
    Name = "${var.name}-natgw"
  }
  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "nat" {
  count      = var.create_nat_gateway ? 1 : 0
  domain = "vpc"
  depends_on = [aws_internet_gateway.this]
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs,(count.index % length(var.azs)))
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, (count.index % length(var.azs)))
  tags = {
    Name = "${var.name}-private-${count.index}"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }
  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public[*].id)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }
  tags = {
    Name = "${var.name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private[*].id)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

############## security Group ######################

resource "aws_security_group" "custom" {
  for_each = var.security_groups

  name        = "${var.name}-${each.key}"
  description = each.value.description
  vpc_id      = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}



locals {
  ingress_rules = flatten([
    for sg_name, sg in var.security_groups : [
      for idx, rule in sg.ingress_rules : {
        id      = "${sg_name}-ingress-${idx}"
        sg_name = sg_name
        rule    = rule
      }
    ]
  ])

  egress_rules = flatten([
    for sg_name, sg in var.security_groups : [
      for idx, rule in sg.egress_rules : {
        id      = "${sg_name}-egress-${idx}"
        sg_name = sg_name
        rule    = rule
      }
    ]
  ])
}


resource "aws_security_group_rule" "ingress" {
  for_each = {
    for r in local.ingress_rules : r.id => r
  }

  type              = "ingress"
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  protocol          = each.value.rule.protocol
  cidr_blocks       = lookup(each.value.rule, "cidr_blocks", [])
  security_group_id = aws_security_group.custom[each.value.sg_name].id
}

resource "aws_security_group_rule" "egress" {
  for_each = {
    for r in local.egress_rules : r.id => r
  }

  type              = "egress"
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  protocol          = each.value.rule.protocol
  cidr_blocks       = lookup(each.value.rule, "cidr_blocks", [])
  security_group_id = aws_security_group.custom[each.value.sg_name].id
}