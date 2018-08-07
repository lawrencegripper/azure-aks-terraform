locals {
  cluster_name               = "aks-${random_integer.random_int.result}"
  agents_resource_group_name = "MC_${var.resource_group_name}_${local.cluster_name}_${azurerm_resource_group.cluster.location}"
}

resource "azurerm_resource_group" "cluster" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

module "service_principal" {
  source = "service_principal"

  sp_name                = "${local.cluster_name}"
}

#an attempt to keep the AKS name (and dns label) somewhat unique
resource "random_integer" "random_int" {
  min = 100
  max = 999
}

resource "azurerm_kubernetes_cluster" "aks" {
  name       = "${local.cluster_name}"
  location   = "${azurerm_resource_group.cluster.location}"
  dns_prefix = "${local.cluster_name}"

  resource_group_name = "${azurerm_resource_group.cluster.name}"
  kubernetes_version  = "${var.kubetnetes_version}"

  linux_profile {
    admin_username = "${var.linux_admin_username}"

    ssh_key {
      // If the user hasn't set a key the default will be "user_users_ssh_key", here we check for that and 
      // load the ssh from file if this is the case. 
      key_data = "${var.linux_admin_ssh_publickey == "use_users_ssh_key" ? file("~/.ssh/id_rsa.pub") : var.linux_admin_ssh_publickey}"
    }
  }

  agent_pool_profile {
    name    = "agentpool"
    count   = "${var.node_count}"
    vm_size = "${var.vm_size}"
    os_type = "Linux"
  }

  service_principal {
    client_id     = "${module.service_principal.client_id}"
    client_secret = "${module.service_principal.client_secret}"
  }
}

data "azurerm_resource_group" "agents" {
  name = "${local.agents_resource_group_name}"
}

resource "azurerm_role_assignment" "aks_service_principal_role_agents" {
  scope                = "${data.azurerm_resource_group.agents.id}"
  role_definition_name = "${module.service_principal.aks_role_name}"
  principal_id         = "${module.service_principal.client_id}"

  depends_on = [
    "azurerm_kubernetes_cluster.aks"
  ]
}



resource "random_id" "redis" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}

provider "kubernetes" {
  host = "${azurerm_kubernetes_cluster.aks.kube_config.0.host}"

  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)}"
}
# resource "azurerm_redis_cache" "redis" {
#   name                = "redis${random_id.redis.hex}"
#   location            = "${azurerm_resource_group.cluster.location}"
#   resource_group_name = "${azurerm_resource_group.cluster.name}"
#   capacity            = 0
#   family              = "C"
#   sku_name            = "Basic"
#   enable_non_ssl_port = false

#   redis_configuration {}
# }


# resource "kubernetes_secret" "redis_secret" {
#   metadata {
#     name = "rediskeys"
#   }

#   data {
#     host = "${azurerm_redis_cache.redis.hostname}"
#     port = "${azurerm_redis_cache.redis.port}"
#     key  = "${azurerm_redis_cache.redis.primary_access_key}"
#   }
# }

module "oms" {
  source = "oms"

  resource_group_name     = "${var.resource_group_name}"
  resource_group_location = "${var.resource_group_location}"
}
