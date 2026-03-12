
path "kvstores/${Kvv2StoreName}/data/${UserPassUserName}/*" {
  capabilities = ["list", "create", "update", "read", "patch", "delete"]
}

path "kvstores/${Kvv2StoreName}/metadata/${UserPassUserName}/*" {
  capabilities = ["list", "create", "update", "read", "patch", "delete"]
}

path "kvstores/${Kvv2StoreName}/*" {
  capabilities = ["list"]
}

path "kvstores/${Kvv2StoreName}/data/+/sharedsecrets/*" {
  capabilities = ["read"]
}