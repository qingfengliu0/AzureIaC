variable "resource_group_name" {
  default = "resume"
}

variable "location"{
    default = "westus2"
}

variable "computer_name"{
  default = "mimi"
}

variable "admin_username"{
  default = "domainadmin"
}

variable "admin_password"{
  description = "admin password for vm"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Cloudflare email"
  type        = string
  default     = "cacerfengfeng@gmail.com"
}

variable "cloudflare_api_key" {
  description = "Cloudflare API key"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  default     = "dc27c744eb7294ab9415ca44e72c3e22"
}

variable "dns_name" {
  description = "resume.qliu.ca"
  type        = string
  default = "resume.qliu.ca"
}

variable "dns_value" {
  description = "server ip address"
  type        = string
  default = "52.149.3.82"
}

variable "slack_webhook"{
  description = "slack webhook url for alert notification"
  type        = string
  sensitive   = true
}

variable "pagerduty_webhook"{
  description = "pagerduty webhook url for alert notification"
  type        = string
  sensitive   = true
}

variable "azure_subscription_id_prod" {
  description = "Azure Subscription ID for production environment"
  type        = string
  default     = "b8a4d2eb-79b6-4128-89b7-924413033e68" # Replace with your actual production subscription ID
  
}