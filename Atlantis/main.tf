terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
  #backend "azurerm" {
  #  resource_group_name   = "atlantis_rg"
  #  storage_account_name  = "atlantisStorage" # Ensure this follows Azure naming conventions
 #   key                   = "atlantis.tfstate"
 # }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "atlantis_rg" {
  name     = "atlantis-resource-group"
  location = "East US"
}
resource "azurerm_virtual_network" "atlantis_vnet" {
  name                = "atlantis-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.atlantis_rg.location
  resource_group_name = azurerm_resource_group.atlantis_rg.name
}

resource "azurerm_subnet" "atlantis_subnet" {
  name                 = "atlantis-subnet"
  resource_group_name  = azurerm_resource_group.atlantis_rg.name
  virtual_network_name = azurerm_virtual_network.atlantis_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_network_security_group" "atlantis_nsg" {
  name                = "atlantis-nsg"
  location            = azurerm_resource_group.atlantis_rg.location
  resource_group_name = azurerm_resource_group.atlantis_rg.name

  security_rule {
    name                       = "allow_http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4141"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_public_ip" "atlantis_ip" {
  name                = "atlantis_ip"
  location            = azurerm_resource_group.atlantis_rg.location
  resource_group_name = azurerm_resource_group.atlantis_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "atlantis_nic" {
  name                = "atlantis-nic"
  location            = azurerm_resource_group.atlantis_rg.location
  resource_group_name = azurerm_resource_group.atlantis_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlantis_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.atlantis_ip.id
  }

}
resource "azurerm_linux_virtual_machine" "atlantis_vm" {
  name                = "atlantis-vm"
  resource_group_name = azurerm_resource_group.atlantis_rg.name
  location            = azurerm_resource_group.atlantis_rg.location
  size                = "Standard_B1s"

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.atlantis_nic.id,
  ]
  admin_ssh_key {
    username   = "domainadmin"
    public_key = file("../.ssh/id_rsa.pub") # Ensure this path is correct
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

}