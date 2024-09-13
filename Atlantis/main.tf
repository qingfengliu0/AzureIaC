provider "azurerm" {
  features {}
}
 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  backend "azurerm" {
    resource_group_name   = "atlantis-resource-group"
    storage_account_name  = "qliuatlantisstorage" # Ensure this follows Azure naming conventions
    container_name        = "qliutfstatecontainer"
    key                   = "atlantis.tfstate"
  }

  required_version = ">= 1.1.0"
}


data "azurerm_client_config" "current" {}


resource "azurerm_resource_group" "atlantis_rg" {
  name     = "atlantis-resource-group"
  location = "East US"
}


resource "azurerm_storage_account" "qliuatlantisstorage" {
  name                     = "qliuatlantisstorage"
  resource_group_name      = azurerm_resource_group.atlantis_rg.name
  location                 = azurerm_resource_group.atlantis_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Storage Container
resource "azurerm_storage_container" "qliutfstatecontainer" {
  name                  = "qliutfstatecontainer"
  storage_account_name  = azurerm_storage_account.qliuatlantisstorage.name
  container_access_type = "private"
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
  security_rule {
      name                       = "allow_ssh"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
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
    public_key = file("atlantis.pub") # Ensure this path is correct
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

resource "azurerm_key_vault" "kv-qliumain-test" {
  name                        = "kv-qliumain-test"
  location                    = azurerm_resource_group.atlantis_rg.location
  resource_group_name         = azurerm_resource_group.atlantis_rg.name
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
}
