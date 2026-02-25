output "secret_arns" {
  description = "Map of environment variable name to Secrets Manager ARN"
  value = {
    for key, env_var_name in local.secret_definitions :
    env_var_name => aws_secretsmanager_secret.app[key].arn
  }
}
