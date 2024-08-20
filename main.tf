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

resource "azurerm_resource_group" "resume" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "developing IaC for resume website"
    Team        = "Steven"
  }
}
#Create a Blob Storage for holding the static code
resource "azurerm_storage_account" "resumewebstorage" {
  name                     = "resumewebstorage"
  resource_group_name      = azurerm_resource_group.resume.name
  location                 = azurerm_resource_group.resume.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Disable secure transfer required
  enable_https_traffic_only = false
  
  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}
#Create a CDN Profile
resource "azurerm_cdn_profile" "resume-cdn-profile" {
  name                = "resume-cdn-profile"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.resume.name
  sku                 = "Standard_Microsoft"
}

#Create a CDN Endpoint, origin is the web storage endpoint
resource "azurerm_cdn_endpoint" "resume-cdn-endpoint-qliu" {
  name                = "resume-cdn-endpoint-qliu"
  resource_group_name = azurerm_resource_group.resume.name
  profile_name        = azurerm_cdn_profile.resume-cdn-profile.name
  location            = "eastus"
  origin {
    name      = "storage-origin"
    host_name = azurerm_storage_account.resumewebstorage.primary_web_host
    http_port = 80
    https_port = 443
  
  }
  origin_host_header = azurerm_storage_account.resumewebstorage.primary_web_host

  is_http_allowed = true
  is_https_allowed = true

  delivery_rule {
    name = "redirect2https"
    order = 1

    request_uri_condition {
      operator  = "Equal"
      match_values = ["/"]
    }

    request_scheme_condition {
      operator     = "Equal"
      match_values = ["HTTP"]
    }

    url_redirect_action {
      redirect_type = "Found"
      protocol = "Https"
      hostname = azurerm_storage_account.resumewebstorage.primary_web_host
    }
  }
  
}
# Configure the Cloudflare provider
provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

# Define the DNS record
resource "cloudflare_record" "cdn-cname-record" {
  zone_id = var.cloudflare_zone_id
  name    = var.dns_name
  value   = azurerm_cdn_endpoint.resume-cdn-endpoint-qliu.fqdn
  type    = "CNAME"
  ttl     = 300
}

# Add a Custom Domain to the CDN Endpoint
resource "azurerm_cdn_endpoint_custom_domain" "qliu-cdn-domain" {
  name                = "qliu-cdn-domain"
  cdn_endpoint_id     = azurerm_cdn_endpoint.resume-cdn-endpoint-qliu.id
  host_name           = var.dns_name # Your custom domain
  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type = "ServerNameIndication"
    tls_version = "TLS12"
  }


  # Azure CDN requires the custom domain to already have a CNAME entry pointing to the CDN endpoint
}