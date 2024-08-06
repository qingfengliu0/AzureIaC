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
