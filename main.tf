// locals {
//   enviroments = ["Prod", "Staging", "Test", "Dev"]
// }

// resource "vault_mount" "application-per-enviroments" {
//   count = length(local.enviroments)
//   path  = "${var.appname}/${local.enviroments[count.index]}"
//   type  = "generic"
// }

# resource "vault_mount" "application-root" {
#   path  = var.appname
#   type  = "kv-v2"
# }


resource "vault_mount" "application-root-per-env" {
  count = length(var.enviroments)
  path  = "${var.appname}/${var.enviroments[count.index]}"
  type  = "kv-v2"
}

# resource "vault_generic_secret" "application-per-env" {
#   count = length(local.enviroments)
#   path = "${vault_mount.application-root-per-env[count.index].path}"

#     data_json = <<EOT
# {
#   "Description": "Generic KV2 secrets for application ${var.appname} at enviroment ${local.enviroments[count.index]}",
#   "Usage": "You can save your secret into here by vault kv put ${var.appname}/${local.enviroments[count.index]} @secrets.json, where your secrets are saved in secrets.json file"
# }
# EOT

# }



resource "vault_policy" "admin" {
  count = length(var.enviroments)
  name  = "${var.appname}-${var.enviroments[count.index]}-admin"

  policy = <<EOT
path "${var.appname}/${var.enviroments[count.index]}/*" {
  capabilities = ["create", "update", "delete", "list"]
}
EOT
}

resource "vault_policy" "consumer" {
  count = length(var.enviroments)
  name  = "${var.appname}-${var.enviroments[count.index]}-consumer"

  policy = <<EOT
path "${var.appname}/${var.enviroments[count.index]}/*" {
  capabilities = ["read","list"]
}


EOT
}

resource "vault_policy" "superadmin" {
  name = "${var.appname}-superadmin"

  policy = <<EOT
path "${var.appname}/*" {
  capabilities = ["read","create", "update", "delete", "list"]
}
EOT
}