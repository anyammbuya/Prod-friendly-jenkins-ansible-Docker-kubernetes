# ---------------------------------------------------------------------------------------------------
# Create and store Jenkins admin user password
# ---------------------------------------------------------------------------------------------------

resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "jenkins_credentials" {
  kms_key_id              = var.kms_key_id
  name                    = "jenkins-admin-password"
  description             = "Admin password"
  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.jenkins_credentials.id
  secret_string = random_password.master_password.result
}

# ---------------------------------------------------------------------------------------------------
# Create and store database admin user password
# ---------------------------------------------------------------------------------------------------

resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  kms_key_id              = var.kms_key_id
  name                    = "db-admin-password"
  description             = "DB Admin password"
  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "dbsecret" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = random_password.db_master_password.result
}

# ---------------------------------------------------------------------------------------------------
# Store the github Personal Access Token (PAT) for authentication to manage-jenkins github repo
# ---------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "github_ttoken_key" {
  kms_key_id              = var.kms_key_id
  name                    = "github-token"                                  
  description             = "PAT to access manage-jenkins GitHub repo"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "github_PAT_secret_version" {
  secret_id     = aws_secretsmanager_secret.github_ttoken_key.id
  secret_string = file("${path.module}/jenkins-ec2") 
}


# ---------------------------------------------------------------------------------------------------
# Store the Jenkins EC2 deploy ssh private key for authentication to web project github repo
# ---------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "github_deploy_key" {
  kms_key_id              = var.kms_key_id
  name                    = "github-ssh-key"                                  
  description             = "Private deploy key used by Jenkins EC2 to access web project GitHub repo"
  recovery_window_in_days = 0

  tags = {
       "jenkins:credentials:type" = "sshUserPrivateKey",
       "jenkins:credentials:username" = "anyammbuya"
    }

}

resource "aws_secretsmanager_secret_version" "github_deploy_key_version" {
  secret_id     = aws_secretsmanager_secret.github_deploy_key.id
  secret_string = file("${path.module}/id_rsa") 
}

# ---------------------------------------------------------------------------------------------------
# Store the github Personal Access Token (PAT) for github webhook configuration
# https://plugins.jenkins.io/aws-secrets-manager-credentials-provider/
# ---------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "github_webhook_key" {
  kms_key_id              = var.kms_key_id
  name                    = "github_webhook_pat"                                  
  description             = "PAT for github webhook config"
  recovery_window_in_days = 0

   tags = {
       "jenkins:credentials:type" = "string"
    }

}

resource "aws_secretsmanager_secret_version" "github_webhook_key_version" {
  secret_id     = aws_secretsmanager_secret.github_webhook_key.id
  secret_string = file("${path.module}/webhookpat") 
}