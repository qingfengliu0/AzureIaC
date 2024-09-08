terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.1.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.35.0"
    }
  }
  backend "azurerm" {
    resource_group_name   = "atlantis-resource-group"
    storage_account_name  = "qliuatlantisstorage" # Ensure this follows Azure naming conventions
    container_name        = "qliutfstatecontainer"
    key                   = "rg-qliuapi-test.tfstate"
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-qliuapi-test" {
  name     = "rg-qliuapi-test"
  location = "westus2"

  tags = {
    Environment = "Development"
    Description = "Resource group for api resume.qliu.ca"
  }
}

#prequsite for function app, one to many
resource "azurerm_app_service_plan" "asp-qliuapi-test" {
  name                = "asp-qliuapi-test"
  location            = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name

  sku {
    tier = "Standard"
    size = "F1"
  }
}
#storage account for the function apps
resource "azurerm_storage_account" "st-qliuapi-test" {
  name                     = "st-qliuapi-test"
  resource_group_name      = azurerm_resource_group.rg-qliuapi-test.name
  location                 = azurerm_resource_group.rg-qliuapi-test.location
  account_tier             = "Standard"
  #locally redundant storage (LRS)
  account_replication_type = "LRS"

  tags = {
    environment = "Development"
  }
}

#funciton app
resource "azurerm_function_app" "func-recordvisit-test" {
  name                       = "func-recordvisit-test"
  location                   = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name        = azurerm_resource_group.rg-qliuapi-test.name
  app_service_plan_id        = azurerm_app_service_plan.asp-qliuapi-test.id
  storage_account_name       = azurerm_storage_account.st-qliuapi-test.name
  storage_account_access_key = azurerm_storage_account.st-qliuapi-test.primary_access_key
}