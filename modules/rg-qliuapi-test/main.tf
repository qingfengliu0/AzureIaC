#main configuration
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
  location = var.location

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
#Azure log analytics workspace for monitoring the function app
resource "azurerm_log_analytics_workspace" "log-recordvisit-test" {
  name                = "log-recordvisit-test"
  location            = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
  retention_in_days   = 30
}


#Application Insights for monitoring the function app
resource "azurerm_application_insights" "appi-recordvisit-test" {
  name                = "appi-recordvisit-test"
  location            = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
  workspace_id = azurerm_log_analytics_workspace.log-recordvisit-test.id

  application_type = "web"
}


resource "azurerm_linux_function_app" "func-recordvisit-test" {
  name                       = "func-recordvisit-test"
  location                   = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name        = azurerm_resource_group.rg-qliuapi-test.name
  service_plan_id        = azurerm_service_plan.asp-qliuapi-test.id
  storage_account_name = azurerm_storage_account.stqliuapi.name
  storage_account_access_key = azurerm_storage_account.stqliuapi.primary_access_key
 

  site_config {
    cors {
      allowed_origins = ["https://portal.azure.com", "https://resume.qliu.ca"]
    }
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"          = "python"
    "comsmos_container_connection"     = var.db_connectionstring
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appi-recordvisit-test.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.appi-recordvisit-test.instrumentation_key
  }

    lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
      app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"],
      app_settings["WEBSITE_CONTENTSHARE"],
      app_settings["AzureWebJobsStorage"],
      app_settings["AzureWebJobsDashboard"],
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["FUNCTIONS_EXTENSION_VERSION"]
    ]
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


resource "azurerm_monitor_action_group" "ag-qliuapi-test" {
  name                = "ag-qliuapi-test"
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
  short_name          = "API Alert"
  
  azure_app_push_receiver {
    name          = "pushtoadmin"
    email_address = "admin@qliu.com"
  }

  email_receiver{
    name = "admin"
    email_address = "steven@qliu.ca"
  }
  webhook_receiver {
    name                    = "pagerduty"
    service_uri             = "https://events.pagerduty.com/integration/332a617800354b01d0a7da632968bcc8/enqueue"
    use_common_alert_schema = true
  }
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


resource "azurerm_monitor_diagnostic_setting" "diagsetting-recordvisit-test" {
  name                       = "recordvisit-diag"
  target_resource_id         = azurerm_linux_function_app.func-recordvisit-test.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log-recordvisit-test.id

  enabled_log {
    category = "FunctionAppLogs"
  }
    metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_logic_app_workflow" "logic-workflow-qliu-test" {
  name                = "send-slack-notification"
  location            = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
}

resource "azurerm_logic_app_trigger_http_request" "trigger" {
  name         = "incoming_alert"
  logic_app_id = azurerm_logic_app_workflow.logic-workflow-qliu-test.id

  schema = <<JSON
{
  "properties": {
    "message": { "type": "string" }
  },
  "type": "object"
}
JSON
}

resource "azurerm_logic_app_action_http" "send_slack" {
  name         = "send_to_slack"
  logic_app_id = azurerm_logic_app_workflow.logic-workflow-qliu-test.id

  method  = "POST"
  uri     = "https://hooks.slack.com/services/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"
  headers = {
    "Content-Type" = "application/json"
  }

  body = <<JSON
{
  "text": "@{triggerBody().message}"
}
JSON
}

resource "azurerm_monitor_action_group" "slack_logicapp_ag" {
  name                = "ag-forward-to-logicapp"
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name
  short_name          = "SlackAG"
  location            = azurerm_resource_group.rg-qliuapi-test.location

  logic_app_receiver {
    name                    = "logicapp-slack"
    resource_id             = azurerm_logic_app_workflow.logic-workflow-qliu-test.id
    callback_url            = azurerm_logic_app_trigger_http_request.trigger.callback_url
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "ddos_detection" {
  name                = "ddos-detection-alert"
  location            = azurerm_resource_group.rg-qliuapi-test.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-test.name

  data_source_id = azurerm_application_insights.appi-recordvisit-test.id
  description    = "Alert when a single IP sends 20+ requests in 5 seconds"
  enabled        = true

  query = <<-KQL
    requests
    | where timestamp > ago(1m)
    | summarize requestCount = count() by client_IP
    | where requestCount >= 20
  KQL

  severity    = 1
  frequency   = 5
  time_window = 5

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_group           = [azurerm_monitor_action_group.slack_logicapp_ag.id, azurerm_monitor_action_group.ag-qliuapi-test.id]
    email_subject          = "DDoS Detection Alert"
    custom_webhook_payload = jsonencode({
      alertType = "BurstTraffic"
      message   = "20+ requests in 5s from one IP"
    })
  }

  tags = {
    environment = "production"
    type        = "ddos-monitoring"
  }
}
