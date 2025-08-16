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

# Example with ISO 8601 timestamp format
module "app_iso_timestamp" {
  source = "../.."

  app_name     = "iso-app"
  environments = ["dev", "prod"]

  # Explicitly enable AppRole for this example
  enable_approle      = true
  create_admin_policy = false

  # ISO 8601 timestamp format
  timestamp_format = "YYYY-MM-DDTHH:mm:ssZ"

  tags = {
    Team   = "devops"
    Format = "iso8601"
  }
}

# Example with custom timestamp format
module "app_custom_timestamp" {
  source = "../.."

  app_name     = "custom-app"
  environments = ["staging"]

  enable_approle      = false
  create_admin_policy = true

  # Custom timestamp format (e.g., "2025-08-16 14:30:15 UTC")
  timestamp_format = "YYYY-MM-DD HH:mm:ss UTC"

  tags = {
    Team   = "platform"
    Format = "custom"
  }
}

# Example with Unix epoch style
module "app_epoch_timestamp" {
  source = "../.."

  app_name     = "epoch-app"
  environments = ["test"]

  # Explicitly enable AppRole for this example
  enable_approle      = true
  create_admin_policy = false

  # Date only format
  timestamp_format = "YYYY-MM-DD"

  tags = {
    Team   = "qa"
    Format = "date-only"
  }
}

# Outputs showing different timestamp formats
output "iso_creation_time" {
  description = "ISO 8601 formatted creation time"
  value       = module.app_iso_timestamp.creation_time
}

output "custom_creation_time" {
  description = "Custom formatted creation time"
  value       = module.app_custom_timestamp.creation_time
}

output "epoch_creation_time" {
  description = "Date-only formatted creation time"
  value       = module.app_epoch_timestamp.creation_time
}

output "all_summaries" {
  description = "Summaries of all applications with their creation times"
  value = {
    iso_app    = module.app_iso_timestamp.application_summary
    custom_app = module.app_custom_timestamp.application_summary
    epoch_app  = module.app_epoch_timestamp.application_summary
  }
}
