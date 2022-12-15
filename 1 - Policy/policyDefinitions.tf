locals {
  policy_definitions = tolist(fileset(local.library_path, "**/policy_definition_*.{json,json.tftpl}"))
  policy_definitions_dataset = try(length(local.policy_definitions) > 0, false) ? {
    for filepath in local.policy_definitions :
    filepath => jsondecode(file("${local.library_path}/${filepath}"))
  } : null
  policy_definitions_map = try(length(local.policy_definitions_dataset) > 0, false) ? {
    for key, value in local.policy_definitions_dataset :
    value.name => value
    #if value.type == local.resource_types.policy_definition
  } : null
}

resource "azurerm_policy_definition" "policy" {
  for_each = local.policy_definitions_map

  # Mandatory resource attributes
  name         = each.value.name
  policy_type  = "Custom"
  mode         = each.value.properties.mode
  display_name = each.value.properties.displayName

  # Optional resource attributes
  description         = each.value.properties.description
  management_group_id = data.azurerm_management_group.root.id
  policy_rule         = try(length(each.value.properties.policyRule) > 0, false) ? jsonencode(each.value.properties.policyRule) : null
  metadata            = try(length(each.value.properties.metadata) > 0, false) ? jsonencode(each.value.properties.metadata) : null
  parameters          = try(length(each.value.properties.parameters) > 0, false) ? jsonencode(each.value.properties.parameters) : null

  # Set explicit dependency on Management Group deployments
  depends_on = [
    time_sleep.after_management_group,
  ]
}

resource "time_sleep" "after_policy_definition" {
  depends_on = [
    time_sleep.after_management_group,
    azurerm_policy_definition.policy,
  ]

  create_duration  = "30s"
  destroy_duration = "30s"
}