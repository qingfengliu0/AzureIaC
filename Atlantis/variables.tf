variable "admin_password" {
  description = "admin password for vm"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "admin username for vm"
  type        = string
  sensitive   = true
  default     = "domainadmin"
}

variable "tenant_id" {
  description = "tenant id"
  type        = string
  sensitive   = false
  default     = "5caffd0a-25ae-4d12-a6e2-6646216cf62e"
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
}

variable "dns_value" {
  description = "52.149.3.82"
  type        = string
}