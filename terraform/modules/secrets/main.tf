################################################################################
# Application Secrets
# Note: Secret values are NOT managed by Terraform.
# Values are synced from GitHub Secrets via the sync-secrets GitHub Actions workflow.
# Terraform only creates the "container" resources with lifecycle ignore on values.
################################################################################

locals {
  # Maps Secrets Manager key name -> environment variable name
  secret_definitions = {
    "gh-pat"              = "GH_PERSONAL_ACCESS_TOKEN"
    "anthropic-api-key"   = "ANTHROPIC_API_KEY"
    "openai-api-key"      = "OPENAI_API_KEY"
    "gemini-api-key"      = "GEMINI_API_KEY"
    "wandb-api-key"       = "WANDB_API_KEY"
    "langfuse-secret-key" = "LANGFUSE_SECRET_KEY"
    "langfuse-public-key" = "LANGFUSE_PUBLIC_KEY"
    "langfuse-base-url"   = "LANGFUSE_BASE_URL"
    "qdrant-api-key"      = "QDRANT_API_KEY"
    "enterprise-enabled"  = "ENTERPRISE_ENABLED"
    "supabase-url"        = "SUPABASE_URL"
    "supabase-anon-key"   = "SUPABASE_ANON_KEY"
    "supabase-jwt-secret" = "SUPABASE_JWT_SECRET"
    "database-url"        = "DATABASE_URL"
  }
}

resource "aws_secretsmanager_secret" "app" {
  for_each = local.secret_definitions

  name = "${var.project}/${var.environment}/${each.key}"

  tags = {
    Name       = "${var.project}-${var.environment}-${each.key}"
    EnvVarName = each.value
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  for_each = local.secret_definitions

  secret_id     = aws_secretsmanager_secret.app[each.key].id
  secret_string = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [secret_string]
  }
}
