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


