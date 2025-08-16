# Terraform Vault KV for Application

## Project Overview
This is a **modernized and optimized** Terraform module designed to create HashiCorp Vault KV2 (Key-Value version 2) secrets engines for applications across multiple environments. The module automates the creation of mount points, policies, and AppRole authentication configurations to provide secure secrets management with proper access controls.

## Recent Optimizations ✨

The module has been completely refactored according to Terraform best practices:

### **Infrastructure Improvements**
- ✅ **Replaced `count` with `for_each`** for better resource management and state handling
- ✅ **Added comprehensive variable validation** with proper error messages
- ✅ **Implemented proper HCL formatting** and documentation standards
- ✅ **Added `versions.tf`** for explicit provider version constraints
- ✅ **Created comprehensive outputs** for all created resources

### **Security Enhancements**
- ✅ **Improved KV2 policy paths** with proper `data/*` and `metadata/*` separation
- ✅ **Added configurable AppRole security settings** (TTLs, CIDR restrictions, usage limits)
- ✅ **Optional admin policies** (disabled by default for security)
- ✅ **Sensitive output handling** for AppRole credentials

### **Developer Experience**
- ✅ **Added working examples** with both basic and YAML-driven configurations
- ✅ **Created Makefile** for common development tasks (`make fmt`, `make validate`, `make test`)
- ✅ **Added terraform-docs configuration** for automatic documentation
- ✅ **Proper variable naming** (fixed typo: `enviroments` → `environments`)

### **Code Quality**
- ✅ **Removed code duplication** and improved maintainability  
- ✅ **Added proper comments** and documentation throughout
- ✅ **Implemented consistent naming conventions**
- ✅ **Added tags support** for resource organization

## Architecture & Purpose
The module creates a structured approach to secrets management by:
- Creating separate KV2 mount points for each application environment
- Implementing role-based access control (RBAC) with three distinct policy types
- Optionally configuring AppRole authentication for programmatic access
- Supporting multiple environments (dev, test, staging, production, etc.)

## Key Components

### 1. **Vault Mount Points** (`vault_mount`)

- Creates KV2 secrets engines at path: `{app_name}/{environment}`
- One mount point per environment specified in the `environments` variable
- Example paths: `myapp/production`, `myapp/dev`
- Includes proper descriptions and audit logging configuration

### 2. **Access Control Policies**

Three types of policies are created per environment:

#### **Secret Provider Policy** (`secret_provider`)

- **Capabilities**: `create`, `update`, `delete`, `list`
- **Purpose**: For CI/CD systems or services that need to write secrets
- **Cannot**: Read existing secrets (write-only access)
- **Paths**: Covers both `data/*` and `metadata/*` endpoints properly

#### **Secret Consumer Policy** (`secret_consumer`)

- **Capabilities**: `read`, `list`
- **Purpose**: For applications that need to consume secrets
- **Cannot**: Modify or delete secrets (read-only access)
- **Paths**: Proper KV2 `data/*` and `metadata/*` read access

#### **Secret Admin Policy** (`secret_admin`) - Optional

- **Capabilities**: `read`, `create`, `update`, `delete`, `list`
- **Purpose**: For administrators who need full control
- **Scope**: Full access to all environments for the application
- **Default**: Disabled for security (set `create_admin_policy = true` to enable)

### 3. **AppRole Authentication** (Optional)

When `enable_approle = true`, creates AppRole roles for each policy type:
- `{app_name}-{environment}-secret-provider`
- `{app_name}-{environment}-secret-consumer` 
- `{app_name}-{environment}-secret-admin` (if admin policies enabled)

**New AppRole Security Features:**
- Configurable token TTLs and max TTLs
- CIDR-based access restrictions
- Usage limits for tokens and secret IDs
- Proper secret handling in outputs

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `app_name` | string | *required* | Name of the application (with validation) |
| `environments` | list(string) | `["prod", "dev"]` | List of environments to create |
| `approle_path` | string | `"approle"` | Path of the AppRole auth backend |
| `enable_approle` | bool | `true` | Whether to create AppRole roles |
| `create_admin_policy` | bool | `false` | Whether to create admin policies (disabled by default) |
| `tags` | map(string) | `{}` | Additional tags for resources |
| `timestamp_format` | string | `"YYYY-MM-DD hh:mm:ss ZZZ"` | Format for creation time timestamps |
| `approle_token_ttl` | number | `3600` | Default TTL for AppRole tokens (seconds) |
| `approle_token_max_ttl` | number | `86400` | Maximum TTL for AppRole tokens (seconds) |
| `approle_secret_id_ttl` | number | `86400` | TTL for AppRole secret IDs (seconds) |
| `approle_token_num_uses` | number | `0` | Number of uses for tokens (0 = unlimited) |
| `approle_secret_id_num_uses` | number | `0` | Number of uses for secret IDs (0 = unlimited) |
| `approle_secret_id_bound_cidrs` | list(string) | `[]` | CIDR blocks for secret ID authentication |
| `approle_token_bound_cidrs` | list(string) | `[]` | CIDR blocks for token usage |

## Usage Examples

### Basic Usage
```terraform
module "app_secrets" {
  source = "github.com/ausmartway/terraform-vault-kv-for-application"
  
  app_name     = "myapp"
  environments = ["dev", "staging", "prod"]
  
  enable_approle      = true
  create_admin_policy = false
  
  # Security configuration
  approle_token_ttl     = 3600   # 1 hour
  approle_token_max_ttl = 86400  # 24 hours
  
  tags = {
    Team = "platform"
    Environment = "multi"
  }
}
```

### YAML-Driven Configuration
```terraform
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
  
  tags = merge(
    lookup(each.value, "tags", {}),
    { ManagedBy = "terraform-yaml" }
  )
}
```

## File Structure
```
├── main.tf                    # Main resource definitions
├── variables.tf               # Input variable declarations with validation
├── output.tf                  # Comprehensive output definitions
├── versions.tf                # Provider version constraints
├── README.md                  # Module documentation
├── claude.md                  # This file - AI assistant context
├── Makefile                   # Development automation
├── .terraform-docs.yml        # Documentation generation config
├── LICENSE                    # License file
└── examples/
    ├── basic/                 # Basic usage example
    │   └── main.tf
    └── yaml-driven/           # YAML-driven configuration
        ├── main.tf
        └── applications/
            ├── webapp001.yaml
            └── api-service.yaml
```

## Outputs

The module now provides comprehensive outputs:

### **Resource Information**
- `kv_mount_paths` - Map of environment → mount path
- `kv_mount_accessors` - Map of environment → mount accessor
- `secret_provider_policies` - Map of environment → provider policy name
- `secret_consumer_policies` - Map of environment → consumer policy name
- `secret_admin_policies` - Map of environment → admin policy name (if created)

### **AppRole Credentials** (Sensitive)
- `approle_provider_role_ids` - Provider role IDs
- `approle_consumer_role_ids` - Consumer role IDs  
- `approle_admin_role_ids` - Admin role IDs (if created)

### **Summary & Usage**
- `application_summary` - Complete resource summary including creation time
- `usage_examples` - Example commands for using the resources
- `creation_time` - Formatted timestamp of when resources were created

## Creation Time Tracking

The module automatically tracks creation time for audit and management purposes:

### **Features**
- **Mount Descriptions**: KV mount descriptions include creation timestamp
- **Output Values**: Dedicated `creation_time` output with formatted timestamp
- **Application Summary**: Creation time included in comprehensive summary
- **Configurable Format**: Customize timestamp format via `timestamp_format` variable

### **Timestamp Format Examples**
```
"YYYY-MM-DD hh:mm:ss ZZZ"  # Default: 2025-08-16 14:30:15 UTC
"YYYY-MM-DDTHH:mm:ssZ"     # ISO 8601: 2025-08-16T14:30:15Z
"YYYY-MM-DD"               # Date only: 2025-08-16
"DD/MM/YYYY HH:mm UTC"     # Custom: 16/08/2025 14:30 UTC
```

### **Use Cases**
- **Compliance**: Track when secrets infrastructure was created
- **Lifecycle Management**: Identify old resources for cleanup
- **Audit Trails**: Correlate resource creation with deployment events
- **Troubleshooting**: Understand resource age during investigations

## Security Model
The module implements a principle of least privilege:
1. **Separation of Concerns**: Different roles for reading vs writing secrets
2. **Environment Isolation**: Each environment has its own mount point and policies
3. **Application Isolation**: Each application gets its own namespace
4. **Flexible Authentication**: Supports AppRole and can integrate with other auth methods
5. **Configurable Security**: TTLs, CIDR restrictions, and usage limits
6. **Admin Access Control**: Admin policies are opt-in, not default

## Development Workflow

The module includes automation for common development tasks:

```bash
# Format code
make fmt

# Validate all configurations
make validate

# Generate documentation
make docs

# Run comprehensive checks
make check

# Test specific examples
make init-example EXAMPLE=basic
make plan-example EXAMPLE=basic

# Clean temporary files
make clean
```

## Best Practices Implemented
- ✅ **Use `for_each` instead of `count`** for better resource lifecycle management
- ✅ **Validate input variables** to catch configuration errors early
- ✅ **Provide comprehensive outputs** for integration with other modules
- ✅ **Use semantic versioning** in provider constraints
- ✅ **Follow HCL style guidelines** with proper formatting and comments
- ✅ **Implement security defaults** (admin policies disabled by default)
- ✅ **Use descriptive resource names** and consistent conventions
- ✅ **Include working examples** for different use cases
- ✅ **Add proper documentation** and development automation

## Migration from Previous Version

If upgrading from the previous version:

1. **Variable Renames**: `appname` → `app_name`, `enviroments` → `environments`
2. **Resource Changes**: Resources now use `for_each` instead of `count`
3. **New Variables**: Add new security and configuration variables as needed
4. **Admin Policies**: Now opt-in via `create_admin_policy = true`
5. **Outputs**: Many new outputs available for integration

## Dependencies
- HashiCorp Vault with KV2 secrets engine capability
- Terraform >= 1.0
- Vault provider >= 3.0, < 5.0
- AppRole auth method enabled in Vault (if using AppRole functionality)

## Contributing

This module follows Terraform best practices and includes comprehensive testing:

1. **Format**: `make fmt`
2. **Validate**: `make validate` 
3. **Test Examples**: Test both basic and YAML-driven examples
4. **Documentation**: Update docs with `make docs`
5. **Security**: Follow principle of least privilege
