variable "db_connectionstring" {
  description = "connection string to the comos db account" 
  type        = string
  sensitive   = true
}

variable "location"{
  type = string
  default = "westus2"
}

variable "slack_webhook"{
  description = "slack webhook url for alert notification"
  type        = string
  sensitive   = true
}

variable "pagerduty_webhook"{
  description = "slack webhook url for alert notification"
  type        = string
  sensitive   = true
}