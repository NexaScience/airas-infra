variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "enable_basic_auth" {
  description = "Enable Basic authentication via CloudFront Functions"
  type        = bool
  default     = false
}

variable "basic_auth_credentials" {
  description = "Base64-encoded username:password for Basic authentication"
  type        = string
  default     = ""
  sensitive   = true
}
