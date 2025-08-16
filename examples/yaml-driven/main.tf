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

# Local configuration for YAML-driven approach
locals {
  # Read all YAML files from the applications directory
  app_files = fileset(path.module, "applications/*.yaml")

  # Parse YAML files into a list
  app_configs = [
    for file in local.app_files : yamldecode(file("${path.module}/${file}"))
  ]

  # Convert to map for for_each usage
  app_map = {
    for app in local.app_configs : app.app_name => app
  }
}

# Create secrets management for each application
module "applications" {
  source   = "../.."
  for_each = local.app_map

  app_name            = each.value.app_name
  environments        = each.value.environments
  enable_approle      = lookup(each.value, "enable_approle", true)
  create_admin_policy = lookup(each.value, "create_admin_policy", false)

  # AppRole configuration from YAML or defaults
  approle_token_ttl     = lookup(each.value, "approle_token_ttl", 3600)
  approle_token_max_ttl = lookup(each.value, "approle_token_max_ttl", 86400)

  tags = merge(
    lookup(each.value, "tags", {}),
    {
      ManagedBy = "terraform-yaml-driven"
    }
  )
}

# Output summary for all applications
output "applications_summary" {
  description = "Summary of all created applications"
  value = {
    for app_name, module_output in module.applications : app_name => module_output.application_summary
  }
}
