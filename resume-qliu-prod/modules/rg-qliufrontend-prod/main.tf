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
     time = {
      source = "hashicorp/time"
      version = "~> 0.7.0"
    }
  }
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id_prod
}

# resource "azurerm_resource_group" "rg-qliufrontend-prod" {
#   name     = "rg-qliufrontend-prod"
#   location = var.location
#   tags = {
#     Environment = "production"
#     Team        = "Steven"
#   }
# }

# # Create a Blob Storage for holding the static code
# resource "azurerm_storage_account" "st-qliufrontend-prod" {
#   name                     = "stqliufrontendprod" # Ensure this name is globally unique
#   resource_group_name      = azurerm_resource_group.rg-qliufrontend-prod.name
#   location                 = azurerm_resource_group.rg-qliufrontend-prod.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   https_traffic_only_enabled = false 
#   static_website {
#     index_document     = "index.html"
#     error_404_document = "404.html"
#   }
# }

# # Create a CDN Profile
# resource "azurerm_cdn_profile" "cdnp-qliufrontend-prod" {
#   name                = "cdnp-qliufrontend-prod"
#   location            = "eastus"
#   resource_group_name = azurerm_resource_group.rg-qliufrontend-prod.name
#   sku                 = "Standard_Microsoft"
# }

# # Create a CDN Endpoint, origin is the web storage endpoint
# resource "azurerm_cdn_endpoint" "cdne-qliufrontend-prod" {
#   name                = "cdne-qliufrontend-prod"
#   resource_group_name = azurerm_resource_group.rg-qliufrontend-prod.name
#   profile_name        = azurerm_cdn_profile.cdnp-qliufrontend-prod.name # Fixed reference to CDN profile
#   location            = "eastus"
#   origin_path         = "/public" # Ensure this is correct for your static website

#   origin {
#     name      = "storage-origin"
#     host_name = azurerm_storage_account.st-qliufrontend-prod.primary_web_host
#     http_port = 80
#     https_port = 443
#   }
  
#   origin_host_header = azurerm_storage_account.st-qliufrontend-prod.primary_web_host

#   is_http_allowed  = false # Disable HTTP for production
#   is_https_allowed = true

#   delivery_rule {
#     name  = "redirect2https"
#     order = 1

#     request_uri_condition {
#       operator    = "Equal"
#       match_values = ["/"]
#     }

#     request_scheme_condition {
#       operator    = "Equal"
#       match_values = ["HTTP"]
#     }

#     url_redirect_action {
#       redirect_type = "Found"
#       protocol      = "Https"
#       hostname      = azurerm_storage_account.st-qliufrontend-prod.primary_web_host
#     }
#   }
# }

# # Define the DNS record in Cloudflare
# resource "cloudflare_record" "dns-qliufrontend-prod" {
#   zone_id = var.cloudflare_zone_id
#   name    = var.dns_name
#   value   = azurerm_cdn_endpoint.cdne-qliufrontend-prod.fqdn 
#   type    = "CNAME"
#   ttl     = 300
# }

# resource "time_sleep" "wait_60_seconds" {
#   create_duration = "300s" # Wait for 300 seconds for DNS propagation
# }

# # Add a Custom Domain to the CDN Endpoint
# resource "azurerm_cdn_endpoint_custom_domain" "domain-qliufrontend-prod" {
#   name            = "qliu-cdn-domain-prod"
#   cdn_endpoint_id = azurerm_cdn_endpoint.cdne-qliufrontend-prod.id
#   host_name       = var.dns_name # Your custom domain

#   cdn_managed_https {
#     certificate_type = "Dedicated"
#     protocol_type    = "ServerNameIndication"
#     tls_version      = "TLS12"
#   }
# }
