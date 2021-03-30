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

resource "azurerm_storage_share" "ss-server" {
  name                 = "azureheim-server-${var.name_suffix}"
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

resource "azurerm_public_ip" "azureheim" {
  name                = "pubip-azureheim-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/21"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "privatesnet-azureheim-${var.name_suffix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/28"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
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

    volume {
      name                 = "azureheim-server-data"
      mount_path           = "/opt/valheim"
      storage_account_name = azurerm_storage_account.sa.name
      storage_account_key  = azurerm_storage_account.sa.primary_access_key
      share_name           = azurerm_storage_share.ss-server.name
    }
  }
}

resource "azurerm_lb" "lb" {
  name                = "loadbalancer-${var.name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LBPublicIPAddress"
    public_ip_address_id = azurerm_public_ip.azureheim.id
  }
}

resource "azurerm_lb_backend_address_pool" "add_pool" {
  name            = "address-pool-${var.name_suffix}"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_backend_address_pool_address" "pool_address" {
  name                    = "pool-address-${var.name_suffix}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.add_pool.id
  virtual_network_id      = azurerm_virtual_network.vnet.id
  ip_address              = azurerm_container_group.valheim.ip_address
}

resource "azurerm_lb_rule" "lb-rule-2456" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule2456"
  protocol                       = "Udp"
  frontend_port                  = 2456
  backend_port                   = 2456
  backend_address_pool_id        = azurerm_lb_backend_address_pool.add_pool.id
  frontend_ip_configuration_name = "LBPublicIPAddress"
}

resource "azurerm_lb_rule" "lb-rule-2457" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule2457"
  protocol                       = "Udp"
  frontend_port                  = 2457
  backend_port                   = 2457
  backend_address_pool_id        = azurerm_lb_backend_address_pool.add_pool.id
  frontend_ip_configuration_name = "LBPublicIPAddress"
}
