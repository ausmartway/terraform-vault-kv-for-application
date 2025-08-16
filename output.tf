# KV Mount outputs
output "kv_mount_paths" {
  description = "Map of environment names to their KV mount paths"
  value = {
    for env, mount in vault_mount.app_kv : env => mount.path
  }
}

output "kv_mount_accessors" {
  description = "Map of environment names to their KV mount accessors"
  value = {
    for env, mount in vault_mount.app_kv : env => mount.accessor
  }
}

# Policy outputs
output "secret_provider_policies" {
  description = "Map of environment names to secret provider policy names"
  value = {
    for env, policy in vault_policy.secret_provider : env => policy.name
  }
}

output "secret_consumer_policies" {
  description = "Map of environment names to secret consumer policy names"
  value = {
    for env, policy in vault_policy.secret_consumer : env => policy.name
  }
}

output "secret_admin_policies" {
  description = "Map of environment names to secret admin policy names (if created)"
  value = {
    for env, policy in vault_policy.secret_admin : env => policy.name
  }
}

# AppRole outputs (sensitive data)
output "approle_provider_role_ids" {
  description = "Map of environment names to AppRole provider role IDs"
  value = {
    for env, role in vault_approle_auth_backend_role.secret_provider : env => role.role_id
  }
  sensitive = true
}

output "approle_consumer_role_ids" {
  description = "Map of environment names to AppRole consumer role IDs"
  value = {
    for env, role in vault_approle_auth_backend_role.secret_consumer : env => role.role_id
  }
  sensitive = true
}

output "approle_admin_role_ids" {
  description = "Map of environment names to AppRole admin role IDs (if created)"
  value = {
    for env, role in vault_approle_auth_backend_role.secret_admin : env => role.role_id
  }
  sensitive = true
}

# Creation time output
output "creation_time" {
  description = "Timestamp when the resources were created"
  value       = formatdate(var.timestamp_format, timestamp())
}

# Summary outputs for convenience
output "application_summary" {
  description = "Summary of created resources for the application"
  value = {
    app_name        = var.app_name
    environments    = var.environments
    approle_enabled = var.enable_approle
    admin_enabled   = var.create_admin_policy
    created_time    = formatdate(var.timestamp_format, timestamp())
    mount_paths = {
      for env, mount in vault_mount.app_kv : env => mount.path
    }
    policy_names = {
      providers = {
        for env, policy in vault_policy.secret_provider : env => policy.name
      }
      consumers = {
        for env, policy in vault_policy.secret_consumer : env => policy.name
      }
      admins = {
        for env, policy in vault_policy.secret_admin : env => policy.name
      }
    }
  }
}

# Usage examples
output "usage_examples" {
  description = "Example commands for using the created resources"
  value = {
    vault_write_example = "vault kv put ${values(vault_mount.app_kv)[0].path}/myapp/config username=myuser password=mypass"
    vault_read_example  = "vault kv get ${values(vault_mount.app_kv)[0].path}/myapp/config"
    policy_examples = {
      for env in var.environments : env => {
        provider_policy = "${var.app_name}-${env}-secret-provider"
        consumer_policy = "${var.app_name}-${env}-secret-consumer"
        admin_policy    = var.create_admin_policy ? "${var.app_name}-${env}-secret-admin" : "not created"
      }
    }
  }
}