# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
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
  address_prefixes     = ["10.0.2.0/24"]
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
  size                = "Standard_B2"
  admin_username      = "domainadmin"
  network_interface_ids = [
    azurerm_network_interface.resume_nic.id,
  ]

  admin_ssh_key {
    username   = "domainadmin"
    public_key = file("~/.ssh/azure.pub") # Ensure this path is correct
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
