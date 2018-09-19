variable "resource_group_name" {
  type        = "string"
  description = "Name of the azure resource group."
  default     = "akc-rg"
}

variable "resource_group_location" {
  type        = "string"
  description = "Location of the azure resource group."
  default     = "eastus"
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "k8s-workspace"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "standalone"
}


resource "azurerm_log_analytics_solution" "container_insights" {
  location              = "${var.resource_group_location}"
  resource_group_name   = "${var.resource_group_name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.workspace.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.workspace.name}"
  solution_name         = "ContainerInsights"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

output "id" {
  value = "${azurerm_log_analytics_workspace.workspace.id}"
  depends_on = [
    "azurerm_log_analytics_solution.container_insights"
  ]
}