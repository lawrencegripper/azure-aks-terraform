variable "cluster_name" {}
variable "cluster_resource_group_name" {}
variable "agents_resource_group_name" {}

data "azurerm_resource_group" "cluster" {
  name = "${var.cluster_resource_group_name}"
}

data "azurerm_resource_group" "agents" {
  name = "${var.agents_resource_group_name}"
}

resource "azurerm_azuread_application" "aks_app" {
  name = "${var.cluster_name}"
}

resource "azurerm_azuread_service_principal" "aks_sp" {
  application_id = "${azurerm_azuread_application.aks_app.application_id}"
}

resource "random_string" "aks_sp_password" {
  length  = 16
  special = true

  keepers = {
    service_principal = "${azurerm_azuread_service_principal.aks_sp.id}"
  }
}

resource "azurerm_azuread_service_principal_password" "aks_sp_password" {
  service_principal_id = "${azurerm_azuread_service_principal.aks_sp.id}"
  value                = "${random_string.aks_sp_password.result}"
  end_date             = "${timeadd(timestamp(), "8760h")}"

  # This stops be 'end_date' changing on each run and causing a new password to be set
  # to get the date to change here you would have to manually taint this resource...
  lifecycle {
    ignore_changes = ["end_date"]
  }
}

// Attempt to create a 'least privilidge' role for SP used by AKS
resource "azurerm_role_definition" "aks_sp_role_rg" {
  name        = "aks_sp_role"
  scope       = "${data.azurerm_resource_group.agents.id}"
  description = "This role provides the required permissions needed by Kubernetes to: Manager VMs, Routing rules, Mount azure files and Read container repositories"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/routeTables/routes/read",
      "Microsoft.Network/routeTables/routes/write",
      "Microsoft.Storage/storageAccounts/fileServices/fileShare/read",
      "Microsoft.ContainerRegistry/registries/read",
    ]

    not_actions = [
      // Deny access to all VM actions, this includes Start, Stop, Restart, Delete, Redeploy, Login, etc
      "Microsoft.Compute/virtualMachines/*/action",

      "Microsoft.Compute/virtualMachines/extensions",
    ]
  }

  assignable_scopes = [
    "${data.azurerm_resource_group.agents.id}",
  ]
}

resource "azurerm_role_assignment" "aks_service_principal_role_cluster" {
  scope                = "${data.azurerm_resource_group.cluster.id}"
  role_definition_name = "Owner"
  principal_id         = "${azurerm_azuread_service_principal.aks_sp.id}"
}

resource "azurerm_role_assignment" "aks_service_principal_role_agents" {
  scope                = "${data.azurerm_resource_group.agents.id}"
  role_definition_name = "Owner"
  principal_id         = "${azurerm_azuread_service_principal.aks_sp.id}"
}

output "client_id" {
  value = "${azurerm_azuread_service_principal.aks_sp.application_id}"
}

output "client_secret" {
  sensitive = true
  value     = "${random_string.aks_sp_password.result}"
}
