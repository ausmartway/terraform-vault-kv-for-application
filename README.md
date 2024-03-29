# terraform-vault-kv-for-application
Terraform module that creates kv2 secrets engine for application per enviroment, along with secrets provider/consumer/admin policies.


## Usage
```terraform
module "vault_app_module_APP000001" {
    source  = "ausmartway/terraform-vault-kv-for-application"
    version = "0.4.1"
    appname = "APP000001"
    enable_approle = true
    enviroments=["production","dev","test","sit","svt"]
}
```

or, using yaml file as variable input:

```terraform
locals {
  # Take a directory of YAML files, read each one that matches naming pattern and bring them in to Terraform's native data set
  inputappvars = [for f in fileset(path.module, "applications/{app}*.yaml") : yamldecode(file(f))]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map where each top level key is a unique identifier.
  # In this case I am using the appid key from my example YAML files
  inputappmap = { for app in toset(local.inputappvars) : app.appid => app }
}


module "applications" {
  source      = "ausmartway/kv-for-application/vault"
  version     = "0.4.1"
  for_each    = local.inputappmap
  appname     = each.value.appid
  enable_approle = each.value.enable_approle
  enviroments = each.value.enviroments
}

```
