resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name     = each.key
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id
  target_type = each.value.target_type

  health_check {
    path                = each.value.health_check.path
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    matcher             = each.value.health_check.matcher
  }

  tags = var.tags
}

resource "aws_lb_listener" "this" {
  for_each = { for i, listener in var.listeners : i => listener }

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = each.value.default_action.type
    target_group_arn = aws_lb_target_group.this[each.value.default_action.target_group_key].arn
  }
}


resource "aws_lb_target_group_attachment" "this" {
  for_each = {
    for pair in flatten([
      for tg_name, tg in var.target_groups :
      [
        for idx, target in tg.targets : {
          key      = "${tg_name}-${idx}"
          tg_name  = tg_name
          target   = target
        }
      ]
    ]) : pair.key => pair
  }

  target_group_arn = aws_lb_target_group.this[each.value.tg_name].arn
  target_id        = each.value.target.id
  port             = each.value.target.port
}

locals {
  listener_rules = {
    for rule in flatten([
      for listener_idx, listener in var.listeners :
      [
        for rule in lookup(listener, "rules", []) : {
          listener_idx = listener_idx
          rule         = rule
        }
      ]
    ]) : "${rule.listener_idx}-${rule.rule.priority}" => rule
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.listener_rules

  listener_arn = aws_lb_listener.this[each.value.listener_idx].arn
  priority     = each.value.rule.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.rule.target_group_key].arn
  }

  condition {
    path_pattern {
      values = each.value.rule.path_patterns
    }
  }
}


