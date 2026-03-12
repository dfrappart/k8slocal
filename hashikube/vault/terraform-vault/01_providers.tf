######################################################################
# Access to Entra ID
######################################################################




provider "azuread" {
  client_id     = var.AzureADClientID
  client_secret = var.AzureADClientSecret
  tenant_id     = var.AzureTenantID
}

provider "vault" {
  address = var.VaultAddress

  auth_login {
    path = "auth/userpass/login/terraform"
    parameters = {
      username = var.VaultTerraformUsername
      password = file("./terraformvaultpwd.txt")
    }
  }
}

provider "azurerm" {
  features {}

  tenant_id     = var.AzureTenantID
  client_id     = var.AzureClientID
  client_secret = var.AzureClientSecret
  subscription_id = var.AzureSubscriptionId
}