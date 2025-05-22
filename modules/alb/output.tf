output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.this : k => v.arn }
}