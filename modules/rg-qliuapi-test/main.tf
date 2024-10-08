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
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-qliuapi-test" {
  name     = "rg-qliuapi-test"
  location = "westus2"

  tags = {
    Environment = "Development"
    Description = "Resource group for api resume.qliu.ca"
  }
}

#prequsite for function app, one to many
resource "azurerm_service_plan" "asp-qliuapi-test" {
  name                = "asp-qliuapi-test"
  location            = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name

  os_type             = "Linux"
  sku_name            = "Y1"
}
#storage account for the function apps
resource "azurerm_storage_account" "stqliuapi" {
  name                     = "stqliuapi"
  resource_group_name      = azurerm_resource_group.rg-qliuapi-test.name
  location                 = azurerm_resource_group.rg-qliuapi-test.location
  account_tier             = "Standard"
  #locally redundant storage (LRS)
  account_replication_type = "LRS"

  tags = {
    environment = "Development"
  }
}

resource "azurerm_linux_function_app" "func-recordvisit-test" {
  name                       = "func-recordvisit-test"
  location                   = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name        = azurerm_resource_group.rg-qliuapi-test.name
  service_plan_id        = azurerm_service_plan.asp-qliuapi-test.id
  storage_account_name = azurerm_storage_account.stqliuapi.name
  storage_account_access_key = azurerm_storage_account.stqliuapi.primary_access_key
  
  site_config {
    cors{
    allowed_origins = ["https://portal.azure.com", "https://resume.qliu.ca"]
    }
   application_stack {
    python_version = "3.11"
  }
  }

 
  
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"       # Use package deployment method
    "comsmos_container_connection" = var.db_connectionstring
  }



  connection_string {
    name = "comsmos-container-connection"
    value = var.db_connectionstring
    type= "Custom"
  }
  
  identity {
    type = "SystemAssigned"
  }

  
  tags = {
    Environment = "Development"
  }
}

resource "azurerm_log_analytics_workspace" "log-recordvisit-test" {
  name                = "log-recordvisit-test"
  location            = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
  retention_in_days   = 30
}



resource "azurerm_monitor_action_group" "ag-qliuapi-test" {
  name                = "ag-qliuapi-test"
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
  short_name          = "API Alert"
  email_receiver{
    name = "admin"
    email_address = "steven@qliu.ca"
  }
}

resource "azurerm_application_insights" "appi-recordvisit-test" {
  name                = "appi-recordvisit-test"
  location            = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
  workspace_id = azurerm_log_analytics_workspace.log-recordvisit-test.id

  application_type = "web"
}

resource "azurerm_application_insights_smart_detection_rule" "alert-recordvisit-failedtorespond-test" {
  name                    = "Slow page load time"
  application_insights_id = azurerm_application_insights.appi-recordvisit-test.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "alert-recordvisit-highdelayresponse-test" {
  name                    = "Slow server response time"
  application_insights_id = azurerm_application_insights.appi-recordvisit-test.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "alert-recordvisit-dosattack-test" {
  name                    = "Potential security issue detected"
  application_insights_id = azurerm_application_insights.appi-recordvisit-test.id
  enabled                 = true
}

resource "azurerm_user_assigned_identity" "usi-githubaction" {
  location            = azurerm_resource_group.rg-qliuapi-test.location
  name                = "usi-githubaction"
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
}
