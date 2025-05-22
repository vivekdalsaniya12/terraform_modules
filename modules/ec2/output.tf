# output "instance_id" {
#   value = aws_instance.this[*].id
# }
# output "instance_ip" {
#   value = aws_instance.this[*].public_ip
# }

output "instance_ids" {
  value = { for k, inst in aws_instance.this : k => inst.id }
}

output "public_ips" {
  value = { for k, inst in aws_instance.this : k => inst.public_ip }
}