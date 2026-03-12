#############################################################################
#data source for azure ad owners

data "azuread_client_config" "current" {}

#############################################################################
#data source for public IP

data "http" "myip" {
  url = "https://ipinfo.io/ip"
}

#############################################################################
#data source for Microsodt Graph application

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

#############################################################################
#data source for key vault

data "azurerm_key_vault" "hashikube_kv" {
  name                = var.KeyVaultName
  resource_group_name = var.KeyVaultResourceGroupName
}