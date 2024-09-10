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

