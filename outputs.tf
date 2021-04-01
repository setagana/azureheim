output "server_ip" {
  value = "Your Valheim server is setting up, and will soon (might take up to 10 mins for the first startup) be available at IP: ${azurerm_public_ip.azureheim.ip_address}:2456"
}
