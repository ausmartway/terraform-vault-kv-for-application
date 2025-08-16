variable "app_name" {
  type        = string
  description = "Name of the application to be onboarded. Must be a valid identifier."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]$", var.app_name))
    error_message = "App name must start and end with alphanumeric characters and can contain hyphens and underscores."
  }
}

variable "environments" {
  type        = list(string)
  description = "List of environments to create KV mounts and policies for"
  default     = ["prod", "dev"]

  validation {
    condition     = length(var.environments) > 0
    error_message = "At least one environment must be specified."
  }

  validation {
    condition = alltrue([
      for env in var.environments : can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]$", env))
    ])
    error_message = "Environment names must be valid identifiers (alphanumeric, hyphens, underscores)."
  }
}

variable "approle_path" {
  type        = string
  default     = "approle"
  description = "The path of the AppRole auth backend mount"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]$", var.approle_path))
    error_message = "AppRole path must be a valid mount path."
  }
}

variable "enable_approle" {
  type        = bool
  default     = true
  description = "Whether to create AppRole roles for authentication. Use native cloud auth when available."
}

variable "create_admin_policy" {
  type        = bool
  default     = false
  description = "Whether to create admin policies with full access across all environments. Use with caution."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply to resources"
}

variable "timestamp_format" {
  type        = string
  default     = "YYYY-MM-DD hh:mm:ss ZZZ"
  description = "Format for timestamp used in creation time tags and descriptions"

  validation {
    condition     = length(var.timestamp_format) > 0
    error_message = "Timestamp format cannot be empty."
  }
}

# AppRole specific configuration variables
variable "approle_token_ttl" {
  type        = number
  default     = 3600
  description = "Default TTL for AppRole tokens in seconds"

  validation {
    condition     = var.approle_token_ttl > 0 && var.approle_token_ttl <= 86400
    error_message = "Token TTL must be between 1 second and 24 hours (86400 seconds)."
  }
}

variable "approle_token_max_ttl" {
  type        = number
  default     = 86400
  description = "Maximum TTL for AppRole tokens in seconds"

  validation {
    condition     = var.approle_token_max_ttl > 0 && var.approle_token_max_ttl <= 604800
    error_message = "Token max TTL must be between 1 second and 7 days (604800 seconds)."
  }
}

variable "approle_secret_id_ttl" {
  type        = number
  default     = 86400
  description = "TTL for AppRole secret IDs in seconds"

  validation {
    condition     = var.approle_secret_id_ttl > 0
    error_message = "Secret ID TTL must be greater than 0."
  }
}

variable "approle_token_num_uses" {
  type        = number
  default     = 0
  description = "Number of uses allowed for AppRole tokens (0 = unlimited)"

  validation {
    condition     = var.approle_token_num_uses >= 0
    error_message = "Token number of uses must be 0 or greater."
  }
}

variable "approle_secret_id_num_uses" {
  type        = number
  default     = 0
  description = "Number of uses allowed for AppRole secret IDs (0 = unlimited)"

  validation {
    condition     = var.approle_secret_id_num_uses >= 0
    error_message = "Secret ID number of uses must be 0 or greater."
  }
}

variable "approle_secret_id_bound_cidrs" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks that can authenticate using the AppRole secret ID"

  validation {
    condition = alltrue([
      for cidr in var.approle_secret_id_bound_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "approle_token_bound_cidrs" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks that can use the AppRole token"

  validation {
    condition = alltrue([
      for cidr in var.approle_token_bound_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

