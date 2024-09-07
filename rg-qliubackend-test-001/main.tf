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
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-qliubackend-test" {
  name     = "rg-qliubackend-test"
  location = "westus2"

  tags = {
    Environment = "Development"
    Description = "Resource group for storing backend data for resume.qliu.ca"
  }
}

# Azure Cosmos DB account
resource "azurerm_cosmosdb_account" "cosmos-qliubackend-test" {
  name                = "cosmos-qliubackend-test"
  location            = azurerm_resource_group.rg-qliubackend-test.location
  resource_group_name = azurerm_resource_group.rg-qliubackend-test.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  geo_location {
    location          = "westus2"
    failover_priority = 0
  }

  consistency_policy {
    consistency_level = "Strong"
  }
}

# Azure Database
resource "azurerm_cosmosdb_sql_database" "cosmos-sql-db-test" {
  name                = "cosmos-sql-db-test"
  resource_group_name = azurerm_resource_group.rg-qliubackend-test.name
  account_name        = azurerm_cosmosdb_account.cosmos-qliubackend-test.name
  throughput          = 400
}

# Azure Container
resource "azurerm_cosmosdb_sql_container" "cosmos-sql-container-test" {
  name                  = "cosmos-sql-container-test"
  resource_group_name   = azurerm_resource_group.rg-qliubackend-test.name
  account_name          = azurerm_cosmosdb_account.cosmos-qliubackend-test.name
  database_name         = azurerm_cosmosdb_sql_database.cosmos-sql-db-test.name
  partition_key_path   = ["/id"]
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/id/?"
    }

    included_path {
      path = "/visit_count/?"
    }

    excluded_path {
      path = "/logs/?"
    }
  }
}
