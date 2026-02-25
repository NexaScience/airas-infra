output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate_validation.api.certificate_arn
}

output "api_fqdn" {
  description = "API fully qualified domain name"
  value       = aws_route53_record.api.fqdn
}

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "frontend_fqdn" {
  description = "Frontend fully qualified domain name"
  value       = aws_route53_record.frontend.fqdn
}
