# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.1.0"
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
# Configure the Cloudflare provider


module "rg-qliufrontend-test" {
  source = "./modules/rg-qliufrontend-test"
  admin_password = var.admin_password
  cloudflare_api_key = var.cloudflare_api_key
  
}