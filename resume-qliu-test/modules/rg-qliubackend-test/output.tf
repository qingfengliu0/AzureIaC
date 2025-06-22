output "db_connectionstring"{
    description = "connection string for osmos-sql-container-test"
    value = azurerm_cosmosdb_account.cosmos-qliubackend-test.primary_sql_connection_string
}