variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g. airas.io)"
  type        = string
}

variable "api_subdomain" {
  description = "API subdomain (e.g. api, api-dev)"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID"
  type        = string
}

variable "frontend_subdomain" {
  description = "Frontend subdomain for Vercel (e.g. app, dev)"
  type        = string
}
