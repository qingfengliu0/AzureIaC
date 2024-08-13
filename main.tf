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
  cdn_endpoint_id     = azurerm_cdn_endpoint.resume-cdn-endpoint-qliu.id
  host_name           = var.dns_name # Your custom domain
  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type = "ServerNameIndication"
    tls_version = "TLS12"
  }


  # Azure CDN requires the custom domain to already have a CNAME entry pointing to the CDN endpoint
}
#16 creating and configuring the database that record the change. 
# Create the Azurem database account MongoDB
resource "azurerm_cosmosdb_account" "qliudb" {
  name                = "qliudb"
  location            = azurerm_resource_group.resume.location
  resource_group_name = azurerm_resource_group.resume.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  
  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level = "Strong"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}
#Create the Database 
resource "azurerm_cosmosdb_mongo_database" "visitor-counter-db" {
  name                = "visitor-counter-db"
  resource_group_name = azurerm_resource_group.resume.name
  account_name        = azurerm_cosmosdb_account.qliudb.name
  throughput          = 400
}

#Create a container in the database
resource "azurerm_cosmosdb_sql_container" "visitor-count-container" {
  name                  = "visitor-count-container"
  resource_group_name   = azurerm_resource_group.resume.name
  account_name          = azurerm_cosmosdb_account.qliudb.name
  database_name         = azurerm_cosmosdb_mongo_database.visitor-counter-db.name
  partition_key_path    = "/definition/id"
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }

  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }
}
