variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "airas"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}
