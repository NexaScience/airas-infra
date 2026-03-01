output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "NS records to set in the domain registrar account"
  value       = aws_route53_zone.main.name_servers
}

output "frontend_prod_fqdn" {
  description = "Frontend prod domain name"
  value       = aws_route53_record.frontend_prod.fqdn
}

output "frontend_dev_fqdn" {
  description = "Frontend dev domain name"
  value       = aws_route53_record.frontend_dev.fqdn
}
