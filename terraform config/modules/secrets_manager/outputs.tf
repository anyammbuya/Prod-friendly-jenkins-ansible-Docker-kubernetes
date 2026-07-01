/*
output "secret_string" {
  description = "the secret string"
  value       = aws_secretsmanager_secret_version.secret.secret_string
}
*/

output "admin_user_secret_arn" {
  description = "arn of the admin user secret string i.e. password"
  value       = aws_secretsmanager_secret_version.secret.arn
}


output "github_PAT_secret_arn" {
  
  description = "arn of PAT in secrets manager"
  value = aws_secretsmanager_secret.github_ttoken_key.arn
}


output "github_deploy_key_arn" {
  
  description = "arn of github deploy key"
  value = aws_secretsmanager_secret.github_deploy_key.arn
}

output "db_admin_secret_string" {
  
  description = "db user secret string "
  value = aws_secretsmanager_secret_version.dbsecret.secret_string
}

output "db_admin_secret_arn" {
  description = "arn of the db admin user secret string"
  value       = aws_secretsmanager_secret_version.dbsecret.arn
}
