terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.0"
    }
  }
}

provider "vault" {
  # Configure the Vault provider
  # address = "https://vault.example.com"
  # token   = var.vault_token
}

module "app_secrets" {
  source = "../.."

  app_name     = "myapp"
  environments = ["dev", "staging", "prod"]

  enable_approle      = true
  create_admin_policy = false

  # AppRole configuration
  approle_token_ttl     = 3600  # 1 hour
  approle_token_max_ttl = 86400 # 24 hours

  # Timestamp configuration
  timestamp_format = "YYYY-MM-DD hh:mm:ss ZZZ"

  tags = {
    Team        = "platform"
    Environment = "multi"
    Purpose     = "secrets-management"
  }
}

# Example outputs
output "mount_paths" {
  description = "KV mount paths for each environment"
  value       = module.app_secrets.kv_mount_paths
}

output "consumer_policies" {
  description = "Secret consumer policy names"
  value       = module.app_secrets.secret_consumer_policies
}

output "provider_policies" {
  description = "Secret provider policy names"
  value       = module.app_secrets.secret_provider_policies
}

output "creation_time" {
  description = "When the resources were created"
  value       = module.app_secrets.creation_time
}

output "application_summary" {
  description = "Complete summary of the created application resources"
  value       = module.app_secrets.application_summary
}
