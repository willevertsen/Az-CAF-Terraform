locals {
  root_vars = { root_scope_resource_id = data.azurerm_management_group.root.id, 
                current_scope_resource_id = data.azurerm_management_group.root.id, 
                default_location = "eastus2" 
              }
  lz_vars = { root_scope_resource_id = data.azurerm_management_group.root.id, 
              current_scope_resource_id = azurerm_management_group.lz.id, 
              default_location = "eastus2" 
            }
  root-Deploy-ASC-Monitoring = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deploy_asc_monitoring.tmpl.json", local.root_vars))
  lz-Deny-IP-Forwarding = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deny_ip_forwarding.tmpl.json", local.lz_vars))
  lz-Deny-RDP-From-Internet = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deny_rdp_from_internet.tmpl.json", local.lz_vars))
  lz-Deny-Storage-http = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deny_storage_http.tmpl.json", local.lz_vars))
  lz-Deny-Subnet-Without-Nsg = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deny_subnet_without_nsg.tmpl.json", local.lz_vars))
  lz-Deploy-AKS-Policy = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deploy_aks_policy.tmpl.json", local.lz_vars))
  lz-Deploy-SQL-DB-Auditing = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deploy_sql_db_auditing.tmpl.json", local.lz_vars))
  lz-Deploy-SQL-Threat = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deploy_sql_threat.tmpl.json", local.lz_vars))
  lz-Deny-Priv-Escalation-AKS = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deny_priv_escalation_aks.tmpl.json", local.lz_vars))
  lz-Deny-Priv-Containers-AKS = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_deny_priv_containers_aks.tmpl.json", local.lz_vars))
  lz-Enforce-TLS-SSL = jsondecode(templatefile("${local.library_path}/policy_assignments/policy_assignment_es_enforce_tls_ssl.tmpl.json", local.lz_vars))
}

resource "azurerm_management_group_policy_assignment" "root-Deploy-ASC-Monitoring" {
  name                 = local.root-Deploy-ASC-Monitoring.name
  policy_definition_id = local.root-Deploy-ASC-Monitoring.properties.policyDefinitionId
  management_group_id  = local.root-Deploy-ASC-Monitoring.properties.scope

  depends_on = [
    time_sleep.after_management_group,
    time_sleep.after_policy_definition,
    time_sleep.after_policy_set_definition,
  ]
}

# resource "azurerm_management_group_policy_assignment" "lz" {
#   for_each = {for key, value in local.lz_assignments.es_landing_zones.policy_assignments : value.name => value}
  
#   name                 = each.value.name
#   policy_definition_id = "${local.root_id}/providers/Microsoft.Authorization/${each.value.type}/${each.value.name}"
#   management_group_id  = azurerm_management_group.lz.id

#   depends_on = [
#     time_sleep.after_management_group,
#     time_sleep.after_policy_definition,
#     time_sleep.after_policy_set_definition,
#   ]
# }

resource "time_sleep" "after_policy_assignment" {
  depends_on = [
    time_sleep.after_management_group,
    time_sleep.after_policy_definition,
    time_sleep.after_policy_set_definition,
    # azurerm_management_group_policy_assignment.root,
    # azurerm_management_group_policy_assignment.lz,
    # azurerm_management_group_policy_assignment.id,
    # azurerm_management_group_policy_assignment.mgmt,
    # azurerm_management_group_policy_assignment.conn,
  ]

  create_duration  = "30s"
  destroy_duration = "30s"
}