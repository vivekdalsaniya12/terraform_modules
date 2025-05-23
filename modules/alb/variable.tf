variable "name" {
  type        = string
  description = "Name of the ALB"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the ALB"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets for the ALB"
}

variable "security_groups" {
  type        = list(string)
  description = "Security groups for the ALB"
}

variable "listeners" {
  description = "List of listener configurations"
  type = list(object({
    port     = number
    protocol = string
    default_action = object({
      type             = string
      target_group_key = string
    })
    rules = optional(list(object({
      priority = number
      path_patterns = list(string)
      target_group_key = string
    })),[])
  }))
}

variable "target_groups" {
  description = "Map of target groups"
  type = map(object({
    protocol    = string
    port        = number
    target_type = string
    health_check = object({
      path                = string
      interval            = number
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
      matcher             = string
    })
    targets = list(object({
      id   = string
      port = number
    }))
  }))
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply"
}
