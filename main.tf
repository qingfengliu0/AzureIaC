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
    host_name = azurerm_storage_account.resumewebstorage.primary_blob_microsoft_host
    http_port = 80
    https_port = 443
  
  }

  origin_path = "/$web"

  is_http_allowed = true
  is_https_allowed = true

  delivery_rule {
    name = "redirect2https"
    order = 1

    request_uri_condition {
      operator  = "Equal"
      match_values = ["/"]
    }

    url_redirect_action {
      redirect_type = "Found"
      protocol = "Https"
    }
  }
}



# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "main"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resume.location
  resource_group_name = azurerm_resource_group.resume.name
}

# Create a subnet
resource "azurerm_subnet" "main" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.resume.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP
resource "azurerm_public_ip" "resume_ip" {
  name                = "resume-ip"
  location            = azurerm_resource_group.resume.location
  resource_group_name = azurerm_resource_group.resume.name
  allocation_method   = "Dynamic"
}

# Create a network interface
resource "azurerm_network_interface" "resume_nic" {
  name                = "resume-nic"
  location            = azurerm_resource_group.resume.location
  resource_group_name = azurerm_resource_group.resume.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.resume_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "resume_web" {
  name                = "resume-web"
  resource_group_name = azurerm_resource_group.resume.name
  location            = azurerm_resource_group.resume.location
  size                = "Standard_B2s"
  admin_username      = "domainadmin"
  network_interface_ids = [
    azurerm_network_interface.resume_nic.id,
  ]

  admin_ssh_key {
    username   = "domainadmin"
    public_key = file("azure.pub") # Ensure this path is correct
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
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
  cdn_endpoint_id       = azurerm_cdn_endpoint.resume-cdn-endpoint-qliu.id
  host_name            = var.dns_name # Your custom domain

  # Azure CDN requires the custom domain to already have a CNAME entry pointing to the CDN endpoint
}
