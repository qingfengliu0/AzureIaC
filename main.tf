# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.35.0"
    }
  }
  backend "azurerm" {
    resource_group_name   = "resume"
    storage_account_name  = "qliustorage" # Ensure this follows Azure naming conventions
    container_name        = "terraformstate"
    key                   = "terraform.tfstate"
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

module "rg-qliufrontend-test" {
  source = "./modules/rg-qliufrontend-test"
}