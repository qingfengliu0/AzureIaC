variable "db_connectionstring" {
  description = "connection string to the comos db account" 
  type        = string
  sensitive   = true
}

variable "location"{
  type = string
  default = "westus2"
}