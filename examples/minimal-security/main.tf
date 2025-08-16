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

# Example of security-first configuration
# Uses all secure defaults: no AppRole, no admin policies
module "secure_app" {
  source = "../.."

  app_name     = "secure-app"
  environments = ["dev", "prod"]

  # Security-first defaults (these are the defaults, shown for clarity)
  enable_approle      = false  # Use native cloud auth instead
  create_admin_policy = false  # Prevent accidental over-privileging

  tags = {
    Team            = "security"
    SecurityModel   = "native-auth-only"
    AdminAccess     = "disabled"
    AuthMethod      = "cloud-native"
  }
}

# Another example with AppRole explicitly enabled when needed
module "legacy_app" {
  source = "../.."

  app_name     = "legacy-app"
  environments = ["staging"]

  # Explicitly enable AppRole for legacy systems that can't use cloud auth
  enable_approle      = true
  create_admin_policy = false

  # Enhanced AppRole security settings
  approle_token_ttl               = 1800  # 30 minutes
  approle_token_max_ttl           = 3600  # 1 hour max
  approle_secret_id_bound_cidrs   = ["10.0.0.0/8", "172.16.0.0/12"]
  approle_token_bound_cidrs       = ["10.0.0.0/8"]

  tags = {
    Team        = "legacy-systems"
    AuthMethod  = "approle"
    Reason      = "no-cloud-auth-available"
  }
}

# Example showing how to enable admin policies when truly needed
module "admin_app" {
  source = "../.."

  app_name     = "admin-tools"
  environments = ["management"]

  # Minimal auth - no AppRole needed for admin tooling
  enable_approle = false
  
  # Enable admin policies for management tools (use with extreme caution)
  create_admin_policy = true

  tags = {
    Team           = "platform"
    Purpose        = "vault-management"
    AdminAccess    = "enabled"
    JustificationRequired = "true"
  }
}

# Outputs demonstrating security model
output "security_summary" {
  description = "Summary of security configurations"
  value = {
    secure_app = {
      has_approle     = length(module.secure_app.approle_provider_role_ids) > 0
      has_admin       = length(module.secure_app.secret_admin_policies) > 0
      auth_method     = "cloud-native"
      security_level  = "high"
    }
    legacy_app = {
      has_approle     = length(module.legacy_app.approle_provider_role_ids) > 0
      has_admin       = length(module.legacy_app.secret_admin_policies) > 0
      auth_method     = "approle"
      security_level  = "medium"
    }
    admin_app = {
      has_approle     = length(module.admin_app.approle_provider_role_ids) > 0
      has_admin       = length(module.admin_app.secret_admin_policies) > 0
      auth_method     = "cloud-native"
      security_level  = "admin"
    }
  }
}

output "security_recommendations" {
  description = "Security best practices demonstrated"
  value = {
    default_approle_disabled = "✅ AppRole disabled by default - use cloud auth"
    default_admin_disabled   = "✅ Admin policies disabled by default"
    cidr_restrictions       = "✅ Network restrictions when AppRole needed"
    token_limits           = "✅ Short TTLs for enhanced security"
    principle_least_privilege = "✅ Separate read/write policies"
  }
}
