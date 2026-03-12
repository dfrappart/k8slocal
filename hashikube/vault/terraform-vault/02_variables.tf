######################################################
# Variables
######################################################

##############################################################
#Variable declaration for provider

variable "AzureTenantID" {
  type        = string
  description = "The Azure AD tenant ID"
}

variable "AzureClientSecret" {
  type        = string
  description = "The Azure Application secret"

}

variable "AzureClientID" {
  type        = string
  description = "The Azure Client ID"
}

variable "AzureSubscriptionId" {
  type = string
  description = "The subscription id"
}

variable "AzureADClientSecret" {
  type        = string
  description = "The AAD Application secret"

}

variable "AzureADClientID" {
  type        = string
  description = "The AAD Client ID"
}

variable "VaultAddress" {
  type        = string
  description = "The address of the Vault server"
}

variable "VaultServerName" {
  type        = string
  description = "The Vault server name"
}

variable "VaultTerraformUsername" {
  type        = string
  description = "The username for Terraform login to Vault"
}

variable "vault_userpass_users" {
  type = map(object({
    username = string
    password = optional(string, "")

  }))
  default = {
    "user1" = {
      username = "Spike"
      password = "user1"
    }
    "user2" = {
      username = "Faye"
      password = "user2"
    }
    "user3" = {
      username = "Jet"
      password = "user3"
    }
    "user4" = {
      username = "Ed"
      password = ""
    }
    "user5" = {
      username = "Ein"
      password = ""
    }
  }

}

variable "VaultAppRoles" {
  description = "the azure ad app roles you want to create"
  type        = map(any)
  default = {
    "Admin" = {
      "description" = "Vault admin are authorized to setup the application",
      "policies"    = ["admin"]
    }
  }
}

variable "KeyVaultName" {
  type        = string
  description = "The name of the Azure Key Vault"
}

variable "KeyVaultResourceGroupName" {
  type        = string
  description = "The resource group name of the Azure Key Vault"
}