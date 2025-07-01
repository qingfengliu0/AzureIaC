# Configure the Azure provider
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
    key                   = "rg-frontend-prod.tfstate"
}

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id_prod  # Separate subscription for prod
}
# Configure the Cloudflare provider
provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

module "rg-qliufrontend-prod" {
  source = "./modules/rg-qliufrontend-prod"
  admin_password = var.admin_password
  cloudflare_api_key = var.cloudflare_api_key
}

module "rg-qliubackend-prod" {
  source = "./modules/rg-qliubackend-prod"
}

module "rg-qliuapi-prod" {
  source = "./modules/rg-qliuapi-prod"
  db_connectionstring = module.rg-qliubackend-prod.db_connectionstring
  slack_webhook = var.slack_webhook
  pagerduty_webhook = var.pagerduty_webhook
}
