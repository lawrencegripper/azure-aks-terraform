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
  name                = "k8s-workspace-${random_id.workspace.hex}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Free"
}

resource "azurerm_log_analytics_solution" "container_monitoring" {
  location              = "${var.resource_group_location}"
  resource_group_name   = "${var.resource_group_name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.workspace.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.workspace.name}"
  solution_name         = "Containers"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
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
