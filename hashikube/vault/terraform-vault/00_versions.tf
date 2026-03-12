######################################################################
# backend block for partial configuration
######################################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {

    azuread = {
      version = ">= 2.30"
    }

    random = {
      version = ">= 3.4.3"
    }

    tls = {
      version = ">= 4.0.3"
    }

    vault = {
      version = ">= 3.10.0"
    }

  }

  backend "azurerm" {}
}
