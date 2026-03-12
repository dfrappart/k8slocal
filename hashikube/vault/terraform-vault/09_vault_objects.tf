

resource "vault_mount" "kvv2" {
  path = "hashikube/anothersecretstore"
  type = "kv-v2"
  options = {
    version = "2"
    type    = "kv-v2"
  }
  description = "This is an KV Version 2 secret engine mount created by terraform"
}

/*
resource "vault_policy" "accessbebopkv" {
  for_each = var.vault_userpass_users
  name = "${each.value.username}policy"

  policy = templatefile("${path.root}/policies/vault_userpass_users.hcl", {
    Kvv2StoreName    = vault_mount.kvv2.path
    UserPassUserName = each.value.username
  })
}
*/
