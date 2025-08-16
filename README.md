# Terraform Vault KV for Application

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Vault](https://img.shields.io/badge/vault-%23000000.svg?style=for-the-badge&logo=vault&logoColor=white)](https://www.vaultproject.io/)

A Terraform module that creates HashiCorp Vault KV2 secrets engines for applications across multiple environments, along with comprehensive access control policies and optional AppRole authentication.

## Features

- 🏗️ **Environment Isolation**: Creates separate KV2 mount points for each environment
- 🔐 **Role-Based Access Control**: Three distinct policy types (provider, consumer, admin)
- 🔑 **AppRole Integration**: Optional AppRole authentication for CI/CD systems
- 📝 **YAML-Driven Configuration**: Supports both direct and YAML-driven configuration
- 🛡️ **Security Best Practices**: Implements principle of least privilege
- ✅ **Terraform Best Practices**: Uses `for_each`, proper validation, and comprehensive outputs
- 🕒 **Creation Time Tracking**: Automatically tracks creation time in descriptions and outputs

## Quick Start

### Basic Usage

```hcl
module "app_secrets" {
  source = "github.com/ausmartway/terraform-vault-kv-for-application"
  
  app_name     = "myapp"
  environments = ["dev", "staging", "prod"]
  
  enable_approle      = true
  create_admin_policy = false
  
  # Optional: Customize timestamp format
  timestamp_format = "YYYY-MM-DD hh:mm:ss ZZZ"
  
  tags = {
    Team = "platform"
  }
}
```

### YAML-Driven Configuration

```hcl
locals {
  app_configs = [for f in fileset(path.module, "apps/*.yaml") : yamldecode(file(f))]
  app_map     = { for app in local.app_configs : app.app_name => app }
}

module "applications" {
  source   = "github.com/ausmartway/terraform-vault-kv-for-application"
  for_each = local.app_map
  
  app_name     = each.value.app_name
  environments = each.value.environments
  enable_approle = lookup(each.value, "enable_approle", true)
}
```

## Architecture

This module creates the following resources for each application:

### 1. **KV2 Mount Points**
- Path pattern: `{app_name}/{environment}`
- Example: `myapp/prod`, `myapp/dev`

### 2. **Access Control Policies**

#### Secret Provider Policy
- **Purpose**: CI/CD systems that deploy secrets
- **Capabilities**: `create`, `update`, `delete` (write-only)
- **Cannot**: Read existing secrets

#### Secret Consumer Policy  
- **Purpose**: Applications consuming secrets
- **Capabilities**: `read`, `list` (read-only)
- **Cannot**: Modify secrets

#### Secret Admin Policy (Optional)
- **Purpose**: Administrative access
- **Capabilities**: Full access across all environments
- **Scope**: All environments for the application

### 3. **AppRole Authentication** (Optional)
- Creates AppRole roles for each policy type
- Configurable token TTLs and CIDR restrictions
- Suitable when native cloud auth isn't available

## Creation Time Tracking

This module automatically tracks when resources are created:

- **Mount Descriptions**: Includes creation timestamp in KV mount descriptions
- **Output Values**: Provides `creation_time` output with formatted timestamp
- **Application Summary**: Includes creation time in the comprehensive summary
- **Configurable Format**: Use `timestamp_format` variable to customize the format

### Timestamp Format Examples

```hcl
# ISO 8601 format
timestamp_format = "YYYY-MM-DDTHH:mm:ssZ"

# Human readable format (default)
timestamp_format = "YYYY-MM-DD hh:mm:ss ZZZ"

# Date only
timestamp_format = "YYYY-MM-DD"

# Custom format
timestamp_format = "DD/MM/YYYY HH:mm UTC"
```

## Examples

See the [examples](./examples) directory for complete usage examples:

- [Basic Example](./examples/basic) - Simple single application setup
- [YAML-Driven Example](./examples/yaml-driven) - Multiple applications from YAML files
- [Custom Timestamp Example](./examples/custom-timestamp) - Different timestamp format examples

## Development

This project includes several tools for development and validation:

```bash
# Format code
make fmt

# Validate configuration  
make validate

# Generate documentation
make docs

# Run all checks
make check

# Initialize an example
make init-example EXAMPLE=basic

# Clean temporary files
make clean
```
