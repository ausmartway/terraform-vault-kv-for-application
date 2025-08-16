# Local values for reusable expressions
locals {
  # Create a set of environments for for_each loops
  environments_set = toset(var.environments)

  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      Application = var.app_name
      Module      = "terraform-vault-kv-for-application"
      ManagedBy   = "Terraform"
      CreatedTime = formatdate(var.timestamp_format, timestamp())
    }
  )
}

# Create KV2 mount points for each environment
resource "vault_mount" "app_kv" {
  for_each = local.environments_set

  path        = "${var.app_name}/${each.value}"
  type        = "kv-v2"
  description = "KV2 secrets engine for ${var.app_name} ${each.value} environment - Created: ${formatdate(var.timestamp_format, timestamp())}"

  # KV2 specific options
  options = {
    version = "2"
  }

  # Enable audit device logging
  audit_non_hmac_request_keys  = []
  audit_non_hmac_response_keys = []
}

# Secret provider policy - allows write/delete operations but not read
resource "vault_policy" "secret_provider" {
  for_each = local.environments_set

  name = "${var.app_name}-${each.value}-secret-provider"

  policy = <<-EOT
    # Allow secret provider operations for ${var.app_name}/${each.value}
    path "${var.app_name}/${each.value}/data/*" {
      capabilities = ["create", "update", "delete"]
    }
    
    path "${var.app_name}/${each.value}/metadata/*" {
      capabilities = ["create", "update", "delete", "list"]
    }
    
    # Allow listing the mount to check if it exists
    path "${var.app_name}/${each.value}/" {
      capabilities = ["list"]
    }
  EOT
}

# Secret consumer policy - allows read operations only
resource "vault_policy" "secret_consumer" {
  for_each = local.environments_set

  name = "${var.app_name}-${each.value}-secret-consumer"

  policy = <<-EOT
    # Allow secret consumer operations for ${var.app_name}/${each.value}
    path "${var.app_name}/${each.value}/data/*" {
      capabilities = ["read"]
    }
    
    path "${var.app_name}/${each.value}/metadata/*" {
      capabilities = ["read", "list"]
    }
    
    # Allow listing the mount to check if it exists
    path "${var.app_name}/${each.value}/" {
      capabilities = ["list"]
    }
  EOT
}

# Secret admin policy - allows full operations across all environments
resource "vault_policy" "secret_admin" {
  for_each = var.create_admin_policy ? local.environments_set : []

  name = "${var.app_name}-${each.value}-secret-admin"

  policy = <<-EOT
    # Allow secret admin operations for all ${var.app_name} environments
    path "${var.app_name}/*/data/*" {
      capabilities = ["create", "read", "update", "delete"]
    }
    
    path "${var.app_name}/*/metadata/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    
    # Allow listing all mounts for this application
    path "${var.app_name}/*/" {
      capabilities = ["list"]
    }
    
    # Allow configuring the KV engine
    path "${var.app_name}/*/config" {
      capabilities = ["read", "update"]
    }
  EOT
}

# AppRole authentication roles (optional)
# Note: AppRole is intended when there is no better/native authentication method
# (e.g., AWS IAM, GCP Service Accounts, Azure MSI, Kubernetes Service Accounts, LDAP)

resource "vault_approle_auth_backend_role" "secret_provider" {
  for_each = var.enable_approle ? local.environments_set : []

  backend               = var.approle_path
  role_name             = "${var.app_name}-${each.value}-secret-provider"
  token_policies        = [vault_policy.secret_provider[each.key].name]
  token_ttl             = var.approle_token_ttl
  token_max_ttl         = var.approle_token_max_ttl
  secret_id_ttl         = var.approle_secret_id_ttl
  token_num_uses        = var.approle_token_num_uses
  secret_id_num_uses    = var.approle_secret_id_num_uses
  bind_secret_id        = true
  secret_id_bound_cidrs = var.approle_secret_id_bound_cidrs
  token_bound_cidrs     = var.approle_token_bound_cidrs
}

resource "vault_approle_auth_backend_role" "secret_consumer" {
  for_each = var.enable_approle ? local.environments_set : []

  backend               = var.approle_path
  role_name             = "${var.app_name}-${each.value}-secret-consumer"
  token_policies        = [vault_policy.secret_consumer[each.key].name]
  token_ttl             = var.approle_token_ttl
  token_max_ttl         = var.approle_token_max_ttl
  secret_id_ttl         = var.approle_secret_id_ttl
  token_num_uses        = var.approle_token_num_uses
  secret_id_num_uses    = var.approle_secret_id_num_uses
  bind_secret_id        = true
  secret_id_bound_cidrs = var.approle_secret_id_bound_cidrs
  token_bound_cidrs     = var.approle_token_bound_cidrs
}

resource "vault_approle_auth_backend_role" "secret_admin" {
  for_each = var.enable_approle && var.create_admin_policy ? local.environments_set : []

  backend               = var.approle_path
  role_name             = "${var.app_name}-${each.value}-secret-admin"
  token_policies        = [vault_policy.secret_admin[each.key].name]
  token_ttl             = var.approle_token_ttl
  token_max_ttl         = var.approle_token_max_ttl
  secret_id_ttl         = var.approle_secret_id_ttl
  token_num_uses        = var.approle_token_num_uses
  secret_id_num_uses    = var.approle_secret_id_num_uses
  bind_secret_id        = true
  secret_id_bound_cidrs = var.approle_secret_id_bound_cidrs
  token_bound_cidrs     = var.approle_token_bound_cidrs
}