# output "resource_group_id" {
#   value = azurerm_resource_group.resume.id
# }

# output "cdn_endpoint" {
#   value = azurerm_cdn_endpoint.resume-cdn-endpoint-qliu.fqdn
# }

output "frontend_static_website_host" {
  value = module.rg-qliufrontend-test.static_website_host
}

output "frontend_public_index_url" {
  value = module.rg-qliufrontend-test.public_index_url
}

output "frontend_cloudflare_record_hostname" {
  value = module.rg-qliufrontend-test.cloudflare_record_hostname
}

output "frontend_cloudflare_record_value" {
  value = module.rg-qliufrontend-test.cloudflare_record_value
}

output "frontend_cloudflare_record_proxied" {
  value = module.rg-qliufrontend-test.cloudflare_record_proxied
}
