


resource "vault_jwt_auth_backend" "VaultOidcBackend" {
    description         = "Azure Entra OIDC Auth Method, configured thorugh terraform"
    path                = "oidc-entra"
    type                = "oidc"
    oidc_discovery_url  = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
    oidc_client_id      = azuread_application.VaultOidcApp.client_id
    oidc_client_secret  = azuread_application_password.VaultOidcAppSPSecret.value
    bound_issuer        = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
    tune {
      default_lease_ttl = "1h"
      max_lease_ttl = "1h"
      token_type = "default-service"
    }
}

resource "vault_jwt_auth_backend_role" "azuread" {
  backend        = vault_jwt_auth_backend.VaultOidcBackend.path
  role_name      = "azuread"
  token_policies = ["default", "reader"]

  user_claim   = "email"
  groups_claim = "roles"
  role_type    = "oidc"
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "https://vault.${var.VaultServerName}:8200/ui/vault/auth/${vault_jwt_auth_backend.VaultOidcBackend.path}/oidc/callback"
  ]
}