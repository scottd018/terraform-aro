terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.9.0"
    }
  }
}

provider "azurerm" {
  alias           = "installer"
  client_id       = terraform_data.installer_credentials.output["client_id"]
  client_secret   = terraform_data.installer_credentials.output["client_secret"]
  subscription_id = data.azurerm_client_config.current.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
