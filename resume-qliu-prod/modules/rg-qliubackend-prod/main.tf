# This module inherits provider configuration from the root module

# resource "azurerm_resource_group" "rg-qliubackend-prod" {
#   name     = "rg-qliubackend-prod"
#   location = "westus2"

#   tags = {
#     Environment = "Development"
#     Description = "Resource group for storing backend data for resume.qliu.ca"
#   }
# }

# # Azure Cosmos DB account
# resource "azurerm_cosmosdb_account" "cosmos-qliubackend-prod" {
#   name                = "cosmos-qliubackend-prod"
#   location            = azurerm_resource_group.rg-qliubackend-prod.location
#   resource_group_name = azurerm_resource_group.rg-qliubackend-prod.name
#   offer_type          = "Standard"
#   kind                = "GlobalDocumentDB"
#   geo_location {
#     location          = "westus2"
#     failover_priority = 0
#   }

#   consistency_policy {
#     consistency_level = "Strong"
#   }
# }

# # Azure Database
# resource "azurerm_cosmosdb_sql_database" "cosmos-sql-db-prod" {
#   name                = "cosmos-sql-db-prod"
#   resource_group_name = azurerm_resource_group.rg-qliubackend-prod.name
#   account_name        = azurerm_cosmosdb_account.cosmos-qliubackend-prod.name
#   throughput          = 400
# }

# # Azure Container
# resource "azurerm_cosmosdb_sql_container" "cosmos-sql-container-prod" {
#   name                  = "cosmos-sql-container-prod"
#   resource_group_name   = azurerm_resource_group.rg-qliubackend-prod.name
#   account_name          = azurerm_cosmosdb_account.cosmos-qliubackend-prod.name
#   database_name         = azurerm_cosmosdb_sql_database.cosmos-sql-db-prod.name
#   partition_key_paths   = ["/id"]
#   partition_key_version = 1
#   throughput            = 400

# }
