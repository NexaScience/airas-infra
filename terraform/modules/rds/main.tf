################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}-db-subnet"
  }
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "rds" {
  name_prefix = "${var.project}-${var.environment}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Random Password
################################################################################

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+"
}

################################################################################
# Secrets Manager
################################################################################

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project}/${var.environment}/db-password"

  tags = {
    Name = "${var.project}-${var.environment}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.this.address
    port     = 5432
    dbname   = var.db_name
  })
}

################################################################################
# RDS Instance
################################################################################

resource "aws_db_instance" "this" {
  identifier = "${var.project}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  tags = {
    Name = "${var.project}-${var.environment}-postgres"
  }
}
