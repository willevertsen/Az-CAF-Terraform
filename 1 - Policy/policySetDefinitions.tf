locals {
  policy_set_definitions = tolist(fileset(local.library_path, "**/policy_set_definition_*.{json,json.tftpl}"))
  policy_set_definitions_dataset = try(length(local.policy_set_definitions) > 0, false) ? {
    for filepath in local.policy_set_definitions :
    filepath => jsondecode(templatefile("${local.library_path}/${filepath}", { root_scope_resource_id = data.azurerm_management_group.root.id }))
  } : null
  policy_set_definitions_map = try(length(local.policy_set_definitions_dataset) > 0, false) ? {
    for key, value in local.policy_set_definitions_dataset :
    value.name => value
    #if value.type == local.resource_types.policy_set_definition
  } : null
}

resource "azurerm_policy_set_definition" "policy_set" {
  for_each = local.policy_set_definitions_map

  # Mandatory resource attributes
  name         = each.value.name
  policy_type  = "Custom"
  display_name = each.value.properties.displayName

  # Dynamic configuration blocks
  dynamic "policy_definition_reference" {
    for_each = [
      for item in each.value.properties.policyDefinitions :
      {
        policyDefinitionId          = item.policyDefinitionId
        parameters                  = try(jsonencode(item.parameters), null)
        policyDefinitionReferenceId = try(item.policyDefinitionReferenceId, null)
      }
    ]
    content {
      policy_definition_id = policy_definition_reference.value["policyDefinitionId"]
      parameter_values     = policy_definition_reference.value["parameters"]
      reference_id         = policy_definition_reference.value["policyDefinitionReferenceId"]
    }
  }

  # Optional resource attributes
  description         = try(each.value.properties.description, "${each.value.properties.displayName} Policy Set Definition at scope ${each.value.scope_id}")
  management_group_id = data.azurerm_management_group.root.id
  metadata            = try(length(each.value.properties.metadata) > 0, false) ? jsonencode(each.value.properties.metadata) : null
  parameters          = try(length(each.value.properties.parameters) > 0, false) ? jsonencode(each.value.properties.parameters) : null

  # Set explicit dependency on Management Group and Policy Definition deployments
  depends_on = [
    time_sleep.after_management_group,
    time_sleep.after_policy_definition,
  ]

}

resource "time_sleep" "after_policy_set_definition" {
  depends_on = [
    time_sleep.after_management_group,
    time_sleep.after_policy_definition,
    azurerm_policy_set_definition.policy_set,
  ]

  create_duration  = "30s"
  destroy_duration = "30s"
}