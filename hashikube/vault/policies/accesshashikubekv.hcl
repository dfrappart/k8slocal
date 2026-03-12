
path "hashikube/secrets/data/*" {
  capabilities = ["list", "create", "update", "read", "patch", "delete"]
}

path "hashikube/secrets/metadata/*" {
  capabilities = ["list", "create", "update", "read", "patch", "delete"]
}

