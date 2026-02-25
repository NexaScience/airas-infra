data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "airas-terraform-state-427979936961"
    key    = "global/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  single_nat_gateway   = true
}

module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment
}

module "ecs" {
  source = "../../modules/ecs"

  project     = var.project
  environment = var.environment

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  ecr_repository_url = var.ecr_repository_url
  container_port     = var.container_port
  cpu                = var.cpu
  memory             = var.memory
  desired_count      = var.desired_count
  health_check_path  = "/health"
  enable_autoscaling = false
  enable_https       = true
  certificate_arn    = module.dns.certificate_arn

  secret_arns = module.secrets.secret_arns
}

module "dns" {
  source = "../../modules/dns"

  project     = var.project
  environment = var.environment

  domain_name        = "airas.io"
  api_subdomain      = "api-dev"
  frontend_subdomain = "app-dev"
  zone_id            = data.terraform_remote_state.global.outputs.route53_zone_id
  alb_dns_name       = module.ecs.alb_dns_name
  alb_zone_id        = module.ecs.alb_zone_id
}

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs.ecs_security_group_id

  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention
  deletion_protection     = false
  skip_final_snapshot     = true
}

module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = var.environment

  ecs_cluster_name       = module.ecs.cluster_name
  ecs_service_name       = module.ecs.service_name
  alb_arn_suffix         = module.ecs.alb_arn_suffix
  db_instance_identifier = module.rds.db_instance_identifier
}
