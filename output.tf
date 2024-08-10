output "resource_group_id" {
  value = azurerm_resource_group.resume.id
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.resume_ip.ip_address
}

output "cdn_endpoint" {
  value = azurerm_cdn_endpoint.resume-cdn-endpoint-qliu.fqdn
}
