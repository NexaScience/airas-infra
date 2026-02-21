variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_arn" {
  description = "ALB ARN to associate with WAF"
  type        = string
}

variable "rate_limit" {
  description = "Rate limit per 5-minute period per IP"
  type        = number
  default     = 2000
}
