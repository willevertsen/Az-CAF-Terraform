data "azurerm_management_group" "root" {
  name = var.rootManagementGroup
}

resource "azurerm_management_group" "platform" {
  display_name               = var.platformManagementGroup
  parent_management_group_id = data.azurerm_management_group.root.id
}

resource "azurerm_management_group" "lz" {
  display_name               = var.lzManagementGroup
  parent_management_group_id = data.azurerm_management_group.root.id
}

resource "azurerm_management_group" "decom" {
  display_name               = var.decomManagementGroup
  parent_management_group_id = data.azurerm_management_group.root.id
}

resource "azurerm_management_group" "sandbox" {
  display_name               = var.sandboxManagementGroup
  parent_management_group_id = data.azurerm_management_group.root.id
}

resource "azurerm_management_group" "id" {
  display_name               = var.idManagementGroup
  parent_management_group_id = azurerm_management_group.platform.id

  subscription_ids = var.idManagementGroupSubId
}

resource "azurerm_management_group" "mgmt" {
  display_name               = var.mgmtManagementGroup
  parent_management_group_id = azurerm_management_group.platform.id

  subscription_ids = var.mgmtManagementGroupSubId
}

resource "azurerm_management_group" "connectivity" {
  display_name               = var.connManagementGroup
  parent_management_group_id = azurerm_management_group.platform.id

  subscription_ids = var.connManagementGroupSubId
}

resource "azurerm_management_group" "citrix" {
  display_name               = var.citrixManagementGroup
  parent_management_group_id = azurerm_management_group.lz.id
}

resource "time_sleep" "after_management_group" {
  depends_on = [
    azurerm_management_group.platform,
    azurerm_management_group.lz,
    azurerm_management_group.decom,
    azurerm_management_group.sandbox,
    azurerm_management_group.id,
    azurerm_management_group.mgmt,
    azurerm_management_group.connectivity,
    azurerm_management_group.citrix,
  ]

  create_duration  = "120s"
  destroy_duration = "120s"
}