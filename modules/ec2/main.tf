resource "aws_instance" "this" {
  for_each = { for i, inst in var.instances : i => inst }

  ami = each.value.ami
  instance_type = each.value.instance_type
  subnet_id = each.value.subnet_id
  vpc_security_group_ids = each.value.security_group_ids
  associate_public_ip_address = each.value.associate_public_ip_address
  key_name = each.value.key_name

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${each.value.name}"
    }
  )
}

