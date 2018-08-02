resource "azurerm_resource_group" "cluster" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

resource "random_id" "workspace" {
  keepers = {
    # Generate a new id each time we switch to a new resource group
    group_name = "${azurerm_resource_group.cluster.name}"
  }

  byte_length = 8
}

#an attempt to keep the AKS name (and dns label) somewhat unique
resource "random_integer" "random_int" {
  min = 100
  max = 999
}

resource "azurerm_kubernetes_cluster" "aks" {
  name       = "aks-${random_integer.random_int.result}"
  location   = "${azurerm_resource_group.cluster.location}"
  dns_prefix = "aks-${random_integer.random_int.result}"

  resource_group_name = "${azurerm_resource_group.cluster.name}"
  kubernetes_version  = "1.8.7"

  linux_profile {
    admin_username = "${var.linux_admin_username}"

    ssh_key {
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  agent_pool_profile {
    name    = "agentpool"
    count   = "${var.node_count}"
    vm_size = "${var.node_sku}"
    os_type = "Linux"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }
}
