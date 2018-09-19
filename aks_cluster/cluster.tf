
# Keep the AKS name (and dns label) somewhat unique
resource "random_integer" "random_int" {
  min = 100
  max = 999
}

variable "cluster_name_prefix" {
  description = "Cluster prefix is used to create the clusters name"
}


locals {
  cluster_name               = "${var.cluster_name_prefix}-${random_integer.random_int.result}-${var.location}"
}

# Create a SP for use in the cluster
module "service_principal" {
  source = "service_principal"
  sp_name             = "${local.cluster_name}"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name       = "${local.cluster_name}"
  location   = "${var.location}"
  dns_prefix = "${local.cluster_name}"

  resource_group_name = "${var.resource_group_name}"
  kubernetes_version  = "${var.kubetnetes_version}"

  linux_profile {
    admin_username = "${var.linux_admin_username}"

    ssh_key {
      // If the user hasn't set a key the default will be "user_users_ssh_key", here we check for that and 
      // load the ssh from file if this is the case. 
      key_data = "${var.linux_admin_ssh_publickey}"
    }
  }

  agent_pool_profile {
    name    = "agentpool"
    count   = "${var.node_count}"
    vm_size = "${var.vm_size}"
    os_type = "Linux"

    vnet_subnet_id = "${var.subnet_id}"
  }

  addon_profile {
      oms_agent {
          enabled = true
          log_analytics_workspace_id = "${var.oms_id}"
      }
  }

  network_profile {
    network_plugin = "azure"
  }

  service_principal {
    client_id     = "${module.service_principal.client_id}"
    client_secret = "${module.service_principal.client_secret}"
  }
}

output "kube_config_data" {
  value = {
    client_certificate     = "${azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate}"
    client_key             = "${azurerm_kubernetes_cluster.aks.kube_config.0.client_key}"
    cluster_ca_certificate = "${azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate}"
    kube_config_raw = "${azurerm_kubernetes_cluster.aks.kube_config_raw}"    
  }
}