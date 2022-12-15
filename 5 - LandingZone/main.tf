terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm]
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.con_sub_id
  features {}
}

locals {
  tags = {
    "ManagedBy"       = var.managedby
  }
  approved_regions = {
    "East US 2"    = "eastus2"
    "Central US"   = "centralus"
  }
  region_short = {
    "East US 2"    = "eu2"
    "Central US"   = "cus"
  }
}

# You can use the azurerm_client_config data resource to dynamically
# extract the current Tenant ID from your connection settings.

data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "primary" {
}

data "azurerm_resource_group" "connectivity_primary" {
  name = "ap-rg-network-${local.region_short[var.primary_region]}"
}

data "azurerm_virtual_network" "connectivity_primary" {
  provider = azurerm.connectivity
  name = "ap-vnet-100-${local.region_short[var.primary_region]}"
  resource_group_name = "ap-rg-network-${local.region_short[var.primary_region]}"
}

data "azurerm_resource_group" "connectivity_secondary" {
  name = "ap-rg-network-${local.region_short[var.secondary_region]}"
}

data "azurerm_virtual_network" "connectivity_secondary" {
  provider = azurerm.connectivity
  name = "ap-vnet-200-${local.region_short[var.secondary_region]}"
  resource_group_name = "ap-rg-network-${local.region_short[var.secondary_region]}"
}

resource "azurerm_resource_group" "citrixlz_primary" {
  name     = "ap-rg-citrixlz-${local.region_short[var.primary_region]}"
  location = local.approved_regions[var.primary_region]

  tags = local.tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_resource_group" "citrixlz_secondary" {
  name     = "ap-rg-citrixlz-${local.region_short[var.secondary_region]}"
  location = local.approved_regions[var.secondary_region]

  tags = local.tags
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_network" "citrixlz_primary" {
  name                = "ap-vnet-citrixlz-${local.region_short[var.primary_region]}"
  location            = azurerm_resource_group.citrixlz_primary.location
  resource_group_name = azurerm_resource_group.citrixlz_primary.name
  address_space       = [var.primary_region_cidr]
  dns_servers         = var.primary_region_dns

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_network" "citrixlz_secondary" {
  name                = "ap-vnet-citrixlz-${local.region_short[var.secondary_region]}"
  location            = azurerm_resource_group.citrixlz_secondary.location
  resource_group_name = azurerm_resource_group.citrixlz_secondary.name
  address_space       = [var.secondary_region_cidr]
  dns_servers         = var.secondary_region_dns

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet" "citrixlz_primary" {
  name                 = "ap-snet-citrixlz-${local.region_short[var.primary_region]}"
  resource_group_name  = azurerm_resource_group.citrixlz_primary.name
  virtual_network_name = azurerm_virtual_network.citrixlz_primary.name
  address_prefixes     = [var.primary_region_subnet]

  lifecycle {
    ignore_changes = [enforce_private_link_endpoint_network_policies, delegation]
  }
}

resource "azurerm_subnet" "citrixlz_secondary" {
  name                 = "ap-snet-citrixlz-${local.region_short[var.secondary_region]}"
  resource_group_name  = azurerm_resource_group.citrixlz_secondary.name
  virtual_network_name = azurerm_virtual_network.citrixlz_secondary.name
  address_prefixes     = [var.secondary_region_subnet]

  lifecycle {
    ignore_changes = [enforce_private_link_endpoint_network_policies, delegation]
  }
}

resource "azurerm_network_security_group" "citrixlz_primary_default" {
  name                = "ap-nsg-citrixlz-${local.region_short[var.primary_region]}-default"
  location            = azurerm_resource_group.citrixlz_primary.location
  resource_group_name = azurerm_resource_group.citrixlz_primary.name
  
  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_security_group" "citrixlz_secondary_default" {
  name                = "ap-nsg-citrixlz-${local.region_short[var.secondary_region]}-default"
  location            = azurerm_resource_group.citrixlz_secondary.location
  resource_group_name = azurerm_resource_group.citrixlz_secondary.name

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet_network_security_group_association" "citrixlz_primary_default" {
  subnet_id                 = azurerm_subnet.citrixlz_primary.id
  network_security_group_id = azurerm_network_security_group.citrixlz_primary_default.id
}

resource "azurerm_subnet_network_security_group_association" "citrixlz_secondary_default" {
  subnet_id                 = azurerm_subnet.citrixlz_secondary.id
  network_security_group_id = azurerm_network_security_group.citrixlz_secondary_default.id
}

resource "azurerm_virtual_network_peering" "citrixlz_primary_to_connectivity" {
  name                      = "peercitrixtoconnectivity"
  resource_group_name       = azurerm_resource_group.citrixlz_primary.name
  virtual_network_name      = azurerm_virtual_network.citrixlz_primary.name
  remote_virtual_network_id = data.azurerm_virtual_network.connectivity_primary.id
}

resource "azurerm_virtual_network_peering" "citrixlz_primary_from_connectivity" {
  name                      = "peerconnectivitytocitrix"
  resource_group_name       = data.azurerm_resource_group.connectivity_primary.name
  virtual_network_name      = data.azurerm_virtual_network.connectivity_primary.name
  remote_virtual_network_id = azurerm_virtual_network.citrixlz_primary.id
}

resource "azurerm_virtual_network_peering" "citrixlz_secondary_to_connectivity" {
  name                      = "peercitrixtoconnectivity"
  resource_group_name       = azurerm_resource_group.citrixlz_secondary.name
  virtual_network_name      = azurerm_virtual_network.citrixlz_secondary.name
  remote_virtual_network_id = data.azurerm_virtual_network.connectivity_secondary.id
}

resource "azurerm_virtual_network_peering" "citrixlz_secondary_from_connectivity" {
  name                      = "peerconnectivitytocitrix"
  resource_group_name       = data.azurerm_resource_group.connectivity_secondary.name
  virtual_network_name      = data.azurerm_virtual_network.connectivity_secondary.name
  remote_virtual_network_id = azurerm_virtual_network.citrixlz_secondary.id
}