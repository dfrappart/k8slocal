
resource "random_uuid" "VaultAppRoleUID" {
  for_each = var.VaultAppRoles
}

resource "azuread_application" "VaultOidcApp" {
  display_name = "appreg-vault-oidc-auth"
  #logo_image       = filebase64("./vault_logo.png")
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  dynamic "app_role" {
    for_each = var.VaultAppRoles
    content {
      allowed_member_types = ["User"]
      description          = app_role.value.description
      display_name         = app_role.key
      enabled              = true
      id                   = random_uuid.VaultAppRoleUID[app_role.key].id
      value                = lower(app_role.key)
    }
  }

  group_membership_claims = ["ApplicationGroup"]

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
    resource_access {
      id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  web {
    homepage_url = "https://${var.VaultServerName}:8200"
    redirect_uris = [
      "http://localhost:8250/oidc/callback",
      "https://${var.VaultServerName}:8250/oidc/callback",
      "https://${var.VaultServerName}:8200/ui/vault/auth/oidc/oidc/callback"
    ]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_service_principal" "VaultOidcAppSP" {
  app_role_assignment_required = false
  #owners = azuread_client_config.current.object_id != null ? [azuread_client_config.current.object_id] : []
  client_id = azuread_application.VaultOidcApp.client_id

}

resource "azuread_application_password" "VaultOidcAppSPSecret" {
  application_id  = azuread_application.VaultOidcApp.id
  display_name    = "Vault OIDC App Client Secret"
  
}

resource "azurerm_key_vault_secret" "VaultOidcAppClientSecret" {
  name             = "Vault-Oidc-App-Client-Secret"
  value_wo         = azuread_application_password.VaultOidcAppSPSecret.value
  key_vault_id     = data.azurerm_key_vault.hashikube_kv.id
  value_wo_version = 1
}

resource "azuread_service_principal_delegated_permission_grant" "VaultOidcAppSPGraphUserRead" {
  claim_values                         = ["User.Read", "openid", "profile", "email", "Group.Read.All"]
  service_principal_object_id          = azuread_service_principal.VaultOidcAppSP.object_id
  resource_service_principal_object_id = data.azuread_service_principal.msgraph.object_id

  

}

resource "azuread_application_optional_claims" "VaultOidcAppSPClaims" {
  application_id = azuread_application.VaultOidcApp.id

  access_token {
    name = "email"
  }

  access_token {
    name = "family_name"
  }

  access_token {
    name = "given_name"
  }

  access_token {
    name = "groups"
  }

  id_token {
    name = "groups"
  }

  saml2_token {
    name = "groups"
  }


}