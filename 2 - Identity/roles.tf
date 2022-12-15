resource "azurerm_role_definition" "custom-role-apAdmins" {
  name        = "apAdmins"
  scope       = "/providers/microsoft.management/managementGroups/${var.rootManagementGroup}"
  permissions {
    actions     = ["*"]
    not_actions = []
    data_actions = ["*"]
    not_data_actions = []
  }

  assignable_scopes = [
    "/providers/microsoft.management/managementGroups/${var.rootManagementGroup}"
  ]
}