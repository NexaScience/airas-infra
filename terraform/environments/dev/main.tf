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

module "frontend" {
  source = "../../modules/s3-cloudfront"

  project     = var.project
  environment = var.environment
}
