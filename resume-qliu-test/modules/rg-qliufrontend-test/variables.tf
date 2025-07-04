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
  description = "resumetest.qliu.ca"
  type        = string
  default = "resumetest.qliu.ca"
}

variable "dns_value" {
  description = "server ip address"
  type        = string
  default = "52.149.3.82"
}