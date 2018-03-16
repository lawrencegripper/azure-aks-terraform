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
      key_data = "${var.linux_admin_ssh_publickey}"
    }
  }

  agent_pool_profile {
    name    = "agentpool"
    count   = "2"
    vm_size = "Standard_DS2_v2"
    os_type = "Linux"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "k8s-workspace-${random_id.workspace.hex}"
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  sku                 = "Free"
}

resource "azurerm_log_analytics_solution" "container_monitoring" {
  location              = "${azurerm_resource_group.cluster.location}"
  resource_group_name   = "${azurerm_resource_group.cluster.name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.workspace.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.workspace.name}"
  solution_name         = "Containers"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
}

resource "random_id" "redis" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}

resource "azurerm_redis_cache" "redis" {
  name                = "redis${random_id.redis.hex}"
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false

  redis_configuration {
    maxclients = 256
  }
}

provider "kubernetes" {
  host = "${azurerm_kubernetes_cluster.aks.kube_config.0.host}"

  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)}"
}

resource "kubernetes_secret" "redis_secret" {
  metadata {
    name = "rediskeys"
  }

  data {
    host = "${azurerm_redis_cache.redis.hostname}"
    port = "${azurerm_redis_cache.redis.port}"
    key  = "${azurerm_redis_cache.redis.primary_access_key}"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_secret" "log_analytics_secret" {
  metadata {
    name      = "omsagentkeys"
    namespace = "${kubernetes_namespace.monitoring.metadata.0.name}"
  }

  data {
    workspace_id  = "${azurerm_log_analytics_workspace.workspace.workspace_id}"
    workspace_key = "${azurerm_log_analytics_workspace.workspace.primary_shared_key}"
  }
}

resource "kubernetes_daemonset" "container_agent" {
  metadata {
    name      = "omsagent"
    namespace = "${kubernetes_namespace.monitoring.metadata.0.name}"
  }

  spec {
    selector {
      agentVersion          = "1.4.0-12"
      dockerProviderVersion = "1.0.0-25"
      app                   = "omsagent"
    }

    template {
      metadata {
        labels {
          agentVersion          = "1.4.0-12"
          dockerProviderVersion = "1.0.0-25"
          app                   = "omsagent"
        }
      }

      spec {
        volume {
          name = "docker-sock"

          host_path {
            path = "/var/run/docker.sock"
          }
        }

        volume {
          name = "container-hostname"

          host_path {
            path = "/etc/hostname"
          }
        }

        volume {
          name = "host-log"

          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "container-log"

          host_path {
            path = "/var/lib/docker/containers/"
          }
        }

        container {
          name              = "omsagent"
          image             = "microsoft/oms"
          image_pull_policy = "Always"

          security_context {
            privileged = true
          }

          port {
            container_port = 25225
            protocol       = "TCP"
          }

          port {
            container_port = 25224
            protocol       = "UDP"
          }

          volume_mount {
            name       = "docker-sock"
            mount_path = "/var/run/docker.sock"
          }

          volume_mount {
            mount_path = "/var/log"
            name       = "host-log"
          }

          volume_mount {
            mount_path = "/var/lib/docker/containers/"
            name       = "container-log"
          }

          volume_mount {
            mount_path = "/var/opt/microsoft/omsagent/state/containerhostname"
            name       = "container-hostname"
          }

          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "ps -ef | grep omsagent | grep -v \"grep\""]
            }

            initial_delay_seconds = 60
            period_seconds        = 60
          }

          env = [
            {
              name = "WSID"

              value_from {
                secret_key_ref {
                  name = "${kubernetes_secret.log_analytics_secret.metadata.0.name}"
                  key  = "workspace_id"
                }
              }
            },
            {
              name = "KEY"

              value_from {
                secret_key_ref {
                  name = "${kubernetes_secret.log_analytics_secret.metadata.0.name}"
                  key  = "workspace_key"
                }
              }
            },
          ]
        }
      }
    }
  }
}
