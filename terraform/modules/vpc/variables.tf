variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway (true for dev, false for prod)"
  type        = bool
  default     = true
}
