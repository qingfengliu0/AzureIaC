output "resource_group_id" {
  value = azurerm_resource_group.atlantis_rg.id
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.atlantis_ip.ip_address
}