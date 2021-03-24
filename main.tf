resource "azurerm_resource_group" "rg" {
  name     = "AzureHeim-${var.name_suffix}"
  location = var.location
}

data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "sa" {
  name                     = "azureheim${var.name_suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "ss" {
  name                 = "azureheim-${var.name_suffix}"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 10
}

resource "azurerm_storage_share_directory" "sdir" {
  name                 = "worlds"
  share_name           = azurerm_storage_share.ss.name
  storage_account_name = azurerm_storage_account.sa.name
}

resource "azurerm_storage_share_file" "dbfile" {
  name             = "${var.valheim_world_name}.db"
  storage_share_id = azurerm_storage_share.ss.id
  source           = "${var.valheim_world_name}.db"
  path             = "worlds"
}

resource "azurerm_storage_share_file" "dboldfile" {
  name             = "${var.valheim_world_name}.db.old"
  storage_share_id = azurerm_storage_share.ss.id
  source           = "${var.valheim_world_name}.db.old"
  path             = "worlds"
}

resource "azurerm_storage_share_file" "fwlfile" {
  name             = "${var.valheim_world_name}.fwl"
  storage_share_id = azurerm_storage_share.ss.id
  source           = "${var.valheim_world_name}.fwl"
  path             = "worlds"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-azureheim-${var.name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/21"]
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "pubsnet-azureheim-${var.name_suffix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "privatesnet-azureheim-${var.name_suffix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_public_ip" "azureheim" {
  name                = "pubip-azureheim-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_profile" "nprofile" {
  name                = "networkprofile-azureheim-${var.name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "azureheimcnic"

    ip_configuration {
      name      = "azureheimipconfig"
      subnet_id = azurerm_subnet.private_subnet.id
    }
  }
}

resource "azurerm_container_group" "valheim" {
  name                = "azureheim-${var.name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.nprofile.id
  os_type             = "Linux"
  restart_policy      = "Always"

  container {
    name   = "azureheim-${var.name_suffix}"
    image  = "lloesche/valheim-server"
    cpu    = var.server_cpu
    memory = var.server_memory

    ports {
      port     = 2456
      protocol = "UDP"
    }

    ports {
      port     = 2457
      protocol = "UDP"
    }

    ports {
      port     = 2458
      protocol = "UDP"
    }

    environment_variables = {
      "SERVER_NAME" = var.valheim_server_name
      "WORLD_NAME"  = var.valheim_world_name
      "STATUS_HTTP" = true
    }

    secure_environment_variables = {
      "SERVER_PASS" = var.valheim_server_password
    }

    volume {
      name                 = "azureheim-world-data"
      mount_path           = "/config"
      storage_account_name = azurerm_storage_account.sa.name
      storage_account_key  = azurerm_storage_account.sa.primary_access_key
      share_name           = azurerm_storage_share.ss.name
    }
  }
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "ag" {
  name                = "azureheim-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "azheim-gateway-ip-config-${var.name_suffix}"
    subnet_id = azurerm_subnet.public_subnet.id
  }

  frontend_port {
    name = "${local.frontend_port_name}-2456"
    port = 2456
  }

  frontend_port {
    name = "${local.frontend_port_name}-2457"
    port = 2457
  }

  frontend_port {
    name = "${local.frontend_port_name}-2458"
    port = 2458
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.azureheim.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}-2456"
    cookie_based_affinity = "Disabled"
    port                  = 2456
    protocol              = "Http"
    request_timeout       = 60
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}-2457"
    cookie_based_affinity = "Disabled"
    port                  = 2457
    protocol              = "Http"
    request_timeout       = 60
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}-2458"
    cookie_based_affinity = "Disabled"
    port                  = 2458
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${local.listener_name}-2456"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "${local.frontend_port_name}-2456"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "${local.listener_name}-2457"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "${local.frontend_port_name}-2457"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "${local.listener_name}-2458"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "${local.frontend_port_name}-2458"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-2456"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-2456"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = "${local.http_setting_name}-2456"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-2457"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-2457"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = "${local.http_setting_name}-2457"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-2458"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-2458"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = "${local.http_setting_name}-2458"
  }
}
