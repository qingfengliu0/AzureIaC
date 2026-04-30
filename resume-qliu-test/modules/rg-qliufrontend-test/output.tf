output "static_website_host" {
  value = azurerm_storage_account.st-qliufrontend-test.primary_web_host
}

output "frontend_url" {
  value = "https://${var.dns_name}/"
}

output "cloudflare_record_hostname" {
  value = cloudflare_record.dns-qliufrontend-test.hostname
}

output "cloudflare_record_value" {
  value = cloudflare_record.dns-qliufrontend-test.value
}

output "cloudflare_record_proxied" {
  value = cloudflare_record.dns-qliufrontend-test.proxied
}
