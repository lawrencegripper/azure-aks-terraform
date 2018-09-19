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


resource "random_id" "workspace" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = "${var.resource_group_name}"
  }

  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "k8sworkspace${random_id.workspace.hex}"
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
    promotion_code = ""
  }
}

output "id" {
  value = "${azurerm_log_analytics_workspace.workspace.id}"
  depends_on = [
    "azurerm_log_analytics_solution.container_insights"
  ]
}