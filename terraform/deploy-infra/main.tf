terraform {
  required_providers {
    azurerm = ">= 3.45.0"
  }
}
provider "azurerm" {
  features {
  }
}
## add some comments for visibility
data "azurerm_resource_group" "rg" {
  name = var.rg
}
## local variable for managing tags on the resources
locals {
  tags = {
    environment = "dev"
    project = "teva"
    creator = "terraform"
  }
}
## Virtual Network Block
resource "azurerm_virtual_network" "vnet" {
  name = "VNET-${var.env}-${var.prj}-${var.prjcode}"
  resource_group_name = var.rg
  location = data.azurerm_resource_group.rg.location
  address_space = [ "10.0.0.0/16" ]
  tags = local.tags
}
## Subnet Block for Web App VNet Integration
resource "azurerm_subnet" "subnetwebapp" {
  name = "SUB-${var.env}-${var.prj}-${var.prjcode}-WEBAPP"
  resource_group_name = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.1.0/24" ]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}
## Subnet Block for Core resources
resource "azurerm_subnet" "subnetcore" {
  name = "SUB-${var.env}-${var.prj}-${var.prjcode}-CORE"
  resource_group_name = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.2.0/24" ]
}
## Subnet Block for Flexible PostgreSQL server and database
resource "azurerm_subnet" "subnetpostgre" {
  name = "SUB-${var.env}-${var.prj}-${var.prjcode}-POSTGRE"
  resource_group_name = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.3.0/24" ]
  service_endpoints = [ "Microsoft.Storage" ]
  delegation {
    name = "postgre"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [ "Microsoft.Network/virtualNetworks/subnets/join/action", ]
    }
  }
}
## App Service Plan for Hosting the Web App
resource "azurerm_service_plan" "svcplan" {
  name = "PLA-${var.env}-${var.prj}-${var.prjcode}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location
  os_type = "Linux"
  sku_name = "B1"
  tags = local.tags
}
## Resource Block for Linux Web App
resource "azurerm_linux_web_app" "webapp" {
  name = "WAPP-${var.env}-${var.prj}-${var.prjcode}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location
  service_plan_id = azurerm_service_plan.svcplan.id
  https_only = true
  public_network_access_enabled = false
  site_config {
  }
  virtual_network_subnet_id = azurerm_subnet.subnetwebapp.id
  tags = local.tags
  depends_on = [ azurerm_subnet.subnetwebapp ]
}
## Private DNS Zone for PostgreSQL access
resource "azurerm_private_dns_zone" "postgredns" {
  name = "example.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
  tags = local.tags
}
## Private DNS Zone VNet Link for the PostgreSQL Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "vnetlinkpostgre" {
  name = "postgrevnetzone.com"
  private_dns_zone_name = azurerm_private_dns_zone.postgredns.name
  virtual_network_id = azurerm_virtual_network.vnet.id
  resource_group_name = data.azurerm_resource_group.rg.name
  tags = local.tags
}
## PostgreSQL server anad database configuration block
resource "azurerm_postgresql_flexible_server" "postgreserver" {
  name = "postgre-${var.env}-${var.prj}-${var.prjcode}"
  location = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  version = "14"
  administrator_login = "psqladmin"
  administrator_password = var.pwd
  delegated_subnet_id = azurerm_subnet.subnetpostgre.id
  private_dns_zone_id = azurerm_private_dns_zone.postgredns.id
  sku_name = "B_Standard_B1ms"
  storage_mb = 32768
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.vnetlinkpostgre ]
  tags = local.tags
  zone = "1"
}
## Private Endpoint for the Web App
resource "azurerm_private_endpoint" "pewebapp" {
  name = "PE-${var.env}-${var.prj}-${var.prjcode}"
  location = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id = azurerm_subnet.subnetcore.id
  private_service_connection {
    name = "webappprivateserviceconnection"
    private_connection_resource_id = azurerm_linux_web_app.webapp.id
    is_manual_connection = false
    subresource_names = [ "sites" ]
  }
  private_dns_zone_group {
    name = "webapp-dns-zone-group"
    private_dns_zone_ids = [ azurerm_private_dns_zone.webappdns.id ]
  }
  tags = local.tags
}
## Private DNS Zone for the Web App
resource "azurerm_private_dns_zone" "webappdns" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = data.azurerm_resource_group.rg.name
  tags = local.tags
}
## Private DNS Zone VNET link for the Web App 
resource "azurerm_private_dns_zone_virtual_network_link" "webappvnetlink" {
  name                  = "webapplink"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.webappdns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags = local.tags
}