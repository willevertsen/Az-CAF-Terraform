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

data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "primary" {
}