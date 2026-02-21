output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_secret_arn" {
  description = "DB credentials secret ARN"
  value       = module.rds.db_secret_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.frontend.cloudfront_domain_name
}

output "frontend_bucket_name" {
  description = "Frontend S3 bucket name"
  value       = module.frontend.bucket_name
}
