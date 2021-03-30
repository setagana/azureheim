output "server_ip" {
  value = "Your Valheim server is setting up, and will soon be available at IP: ${azurerm_public_ip.azureheim.ip_address}:2456"
}
