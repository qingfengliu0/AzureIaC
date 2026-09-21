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
#backend storage configuration
backend "azurerm" {
    resource_group_name   = "atlantis-resource-group"
    storage_account_name  = "qliuatlantisstorage" # Ensure this follows Azure naming conventions
    container_name        = "qliutfstatecontainer"
    key                   = "rg-frontend.tfstate"
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}
# Configure the Cloudflare provider
provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

module "rg-qliufrontend-test" {
  source             = "./modules/rg-qliufrontend-test"
  admin_password     = var.admin_password
  cloudflare_email   = var.cloudflare_email
  cloudflare_api_key = var.cloudflare_api_key
  cloudflare_zone_id = var.cloudflare_zone_id
  dns_name           = var.dns_name
}


module "rg-qliubackend-test" {
  source = "./modules/rg-qliubackend-test"
}

module "rg-qliuapi-test" {
  source = "./modules/rg-qliuapi-test"
  db_connectionstring = module.rg-qliubackend-test.db_connectionstring
  slack_webhook = var.slack_webhook
  pagerduty_webhook = var.pagerduty_webhook
}
