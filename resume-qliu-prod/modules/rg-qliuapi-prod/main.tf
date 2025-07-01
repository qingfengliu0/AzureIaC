resource "azurerm_resource_group" "rg-qliuapi-prod" {
  name     = "rg-qliuapi-prod"
  location = var.location

  tags = {
    Environment = "Production"
    Description = "Resource group for api resume.qliu.ca"
  }
}

#prequsite for function app, one to many
resource "azurerm_service_plan" "asp-qliuapi-prod" {
  name                = "asp-qliuapi-prod"
  location            = azurerm_resource_group.rg-qliuapi-prod.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-prod.name

  os_type             = "Linux"
  sku_name            = "Y1"
}
#storage account for the function apps
resource "azurerm_storage_account" "stqliuapiprod" {
  name                     = "stqliuapiprod"
  resource_group_name      = azurerm_resource_group.rg-qliuapi-prod.name
  location                 = azurerm_resource_group.rg-qliuapi-prod.location
  account_tier             = "Standard"
  #locally redundant storage (LRS)
  account_replication_type = "LRS"

  tags = {
    environment = "Production"
  }
}
#Azure log analytics workspace for monitoring the function app
resource "azurerm_log_analytics_workspace" "log-recordvisit-prod" {
  name                = "log-recordvisit-prod"
  location            = azurerm_resource_group.rg-qliuapi-prod.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-prod.name
  retention_in_days   = 30
}


#Application Insights for monitoring the function app
resource "azurerm_application_insights" "appi-recordvisit-prod" {
  name                = "appi-recordvisit-prod"
  location            = azurerm_resource_group.rg-qliuapi-prod.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-prod.name
  workspace_id = azurerm_log_analytics_workspace.log-recordvisit-prod.id

  application_type = "web"
}


resource "azurerm_linux_function_app" "func-recordvisit-prod" {
  name                       = "func-recordvisit-prod"
  location                   = azurerm_resource_group.rg-qliuapi-prod.location
  resource_group_name        = azurerm_resource_group.rg-qliuapi-prod.name
  service_plan_id        = azurerm_service_plan.asp-qliuapi-prod.id
  storage_account_name = azurerm_storage_account.stqliuapiprod.name
  storage_account_access_key = azurerm_storage_account.stqliuapiprod.primary_access_key
 
  depends_on = [
    azurerm_application_insights.appi-recordvisit-prod
  ]

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
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appi-recordvisit-prod.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.appi-recordvisit-prod.instrumentation_key
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
    type = "Custom"
  }
  
  identity {
    type = "SystemAssigned"
  }

  
  tags = {
    Environment = "Production"
  }
}


resource "azurerm_monitor_action_group" "ag-qliuapi-prod" {
  name                = "ag-qliuapi-prod"
  resource_group_name = azurerm_resource_group.rg-qliuapi-prod.name
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
    service_uri             = var.pagerduty_webhook
    use_common_alert_schema = true
  }
}


resource "azurerm_application_insights_smart_detection_rule" "alert-recordvisit-failedtorespond-prod" {
  name                    = "Slow page load time"
  application_insights_id = azurerm_application_insights.appi-recordvisit-prod.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "alert-recordvisit-highdelayresponse-prod" {
  name                    = "Slow server response time"
  application_insights_id = azurerm_application_insights.appi-recordvisit-prod.id
  enabled                 = true
}

resource "azurerm_application_insights_smart_detection_rule" "alert-recordvisit-dosattack-prod" {
  name                    = "Potential security issue detected"
  application_insights_id = azurerm_application_insights.appi-recordvisit-prod.id
  enabled                 = true
}

resource "azurerm_user_assigned_identity" "usi-githubaction-prod" {
  location            = azurerm_resource_group.rg-qliuapi-prod.location
  name                = "usi-githubaction-prod"
  resource_group_name = azurerm_resource_group.rg-qliuapi-prod.name
}


resource "azurerm_monitor_diagnostic_setting" "diagsetting-recordvisit-prod" {
  name                       = "recordvisit-diag"
  target_resource_id         = azurerm_linux_function_app.func-recordvisit-prod.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log-recordvisit-prod.id

  enabled_log {
    category = "FunctionAppLogs"
  }
    metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_logic_app_workflow" "logic-workflow-qliu-prod" {
  name                = "send-slack-notification-prod"
  location            = azurerm_resource_group.rg-qliuapi-prod.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-prod.name
}

resource "azurerm_logic_app_trigger_http_request" "trigger-prod" {
  name         = "incoming_alert"
  logic_app_id = azurerm_logic_app_workflow.logic-workflow-qliu-prod.id

  schema = <<JSON
  {
    "type": "object",
    "properties": {
      "schemaId": { "type": "string" },
      "data": {
        "type": "object",
        "properties": {
          "essentials": {
            "type": "object",
            "properties": {
              "alertRule": { "type": "string" },
              "severity": { "type": "string" },
              "monitorCondition": { "type": "string" },
              "alertTargetIDs": {
                "type": "array",
                "items": { "type": "string" }
              },
              "firedDateTime": { "type": "string" },
              "resolvedDateTime": { "type": "string" },
              "description": { "type": "string" }
            }
          },
          "alertContext": {
            "type": "object",
            "properties": {
              "condition": {
                "type": "object",
                "properties": {
                  "allOf": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "metricName": { "type": "string" },
                        "threshold": { "type": "string" },
                        "metricValue": { "type": "number" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "required": ["schemaId", "data"]
  }
  JSON
}


resource "azurerm_logic_app_action_http" "send_slack_prod" {
  name         = "send_to_slack"
  logic_app_id = azurerm_logic_app_workflow.logic-workflow-qliu-prod.id

  method  = "POST"
  uri     = var.slack_webhook
  headers = {
    "Content-Type" = "application/json"
  }

   body = <<JSON
{
  "text": "@{concat(
    '*Alert Rule:* ', triggerBody()?['data']?['essentials']?['alertRule'], '\n',
    '*Severity:* ', triggerBody()?['data']?['essentials']?['severity'], '\n',
    '*Condition:* ', triggerBody()?['data']?['essentials']?['monitorCondition'], '\n',
    '*Metric:* ', triggerBody()?['data']?['alertContext']?['condition']?['allOf'][0]?['metricName'], '\n',
    '*Metric Value:* ', string(triggerBody()?['data']?['alertContext']?['condition']?['allOf'][0]?['metricValue']), '\n',
    '*Resource:* ', triggerBody()?['data']?['essentials']?['alertTargetIDs'][0]
  )}"
}
JSON
}

resource "azurerm_monitor_action_group" "slack_logicapp_ag_prod" {
  name                = "ag-forward-to-logicapp-prod"
  resource_group_name = azurerm_resource_group.rg-qliuapi-prod.name
  short_name          = "SlackAG"

  logic_app_receiver {
    name                    = "logicapp-slack"
    resource_id             = azurerm_logic_app_workflow.logic-workflow-qliu-prod.id
    callback_url            = azurerm_logic_app_trigger_http_request.trigger-prod.callback_url
    use_common_alert_schema = true
  }
}


resource "azurerm_monitor_scheduled_query_rules_alert" "ddos_detection_prod" {
  name                = "ddos-detection-alert-prod"
  location            = azurerm_resource_group.rg-qliuapi-prod.location
  resource_group_name = azurerm_resource_group.rg-qliuapi-prod.name

  data_source_id = azurerm_application_insights.appi-recordvisit-prod.id
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
    action_group           = [azurerm_monitor_action_group.slack_logicapp_ag_prod.id, azurerm_monitor_action_group.ag-qliuapi-prod.id]
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
