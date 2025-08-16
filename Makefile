.PHONY: help fmt validate docs test clean examples

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

fmt: ## Format Terraform code
	terraform fmt -recursive .
	@echo "✅ Terraform files formatted"

validate: ## Validate Terraform configuration
	@echo "🔍 Validating main module..."
	terraform init -backend=false
	terraform validate
	@echo "🔍 Validating examples..."
	@for example in examples/*/; do \
		echo "Validating $$example"; \
		cd "$$example" && terraform init -backend=false && terraform validate && cd ../..; \
	done
	@echo "✅ All Terraform configurations validated"

docs: ## Generate documentation using terraform-docs
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs .; \
		echo "✅ Documentation generated"; \
	else \
		echo "❌ terraform-docs not found. Install it from https://terraform-docs.io/"; \
		exit 1; \
	fi

test: fmt validate ## Run all tests
	@echo "✅ All tests passed"

clean: ## Clean up temporary files
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfstate*" -delete 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "✅ Cleaned up temporary files"

examples: ## Show example usage
	@echo "📖 Example usage:"
	@echo ""
	@echo "Basic usage:"
	@cat examples/basic/main.tf | grep -A 15 "module \"app_secrets\""
	@echo ""
	@echo "See examples/ directory for more detailed examples"

check: fmt validate docs test ## Run comprehensive checks

init-example: ## Initialize a specific example (usage: make init-example EXAMPLE=basic)
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "❌ Please specify an example: make init-example EXAMPLE=basic"; \
		exit 1; \
	fi
	@if [ ! -d "examples/$(EXAMPLE)" ]; then \
		echo "❌ Example '$(EXAMPLE)' not found"; \
		exit 1; \
	fi
	cd examples/$(EXAMPLE) && terraform init
	@echo "✅ Example '$(EXAMPLE)' initialized"

plan-example: ## Plan a specific example (usage: make plan-example EXAMPLE=basic)
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "❌ Please specify an example: make plan-example EXAMPLE=basic"; \
		exit 1; \
	fi
	@if [ ! -d "examples/$(EXAMPLE)" ]; then \
		echo "❌ Example '$(EXAMPLE)' not found"; \
		exit 1; \
	fi
	cd examples/$(EXAMPLE) && terraform plan
	@echo "✅ Example '$(EXAMPLE)' planned"
