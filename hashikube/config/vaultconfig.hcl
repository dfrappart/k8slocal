storage "raft" {
  path    = "/opt/vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  #tls_disable = "true"
  tls_cert_file = "/etc/vault.d/tls/vault.crt"
  tls_key_file  = "/etc/vault.d/tls/vault.key"
  tls_ca_file   = "/etc/vault.d/tls/vault-ca.crt"
}

api_addr = "https://0.0.0.0:8200"
cluster_addr = "https://serverip:8201"
ui = true
disable_mlock = true

#seal "azurekeyvault" {
#  tenant_id      = ""
#  client_id      = ""
#  client_secret  = ""
#  vault_name     = ""
#  key_name       = ""
#}

