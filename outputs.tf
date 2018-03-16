// These outputs can be used to deploy the monitoring Daemonset into your k8s cluster
// https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-monitor
output "workspace_id" {
  value = "${azurerm_log_analytics_workspace.workspace.workspace_id}"
}

output "workspace_key" {
  value = "${azurerm_log_analytics_workspace.workspace.primary_shared_key}"
}

output "cluster_details_client_cert" {
  value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)}"
}

output "cluster_details_client_key" {
  value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)}"
}

output "cluster_details_ca" {
  value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)}"
}

# output "redis_name" {
#   value = "${azurerm_redis_cache.redis.name}"
# }


# output "redis_hostname" {
#   value = "${azurerm_redis_cache.redis.hostname}"
# }


# output "redis_port" {
#   value = "${azurerm_redis_cache.redis.port}"
# }


# output "redis_primary_access_key" {
#   sensitive = true
#   value     = "${azurerm_redis_cache.redis.primary_access_key}"
# }


# output "redis_secondary_access_key" {
#   sensitive = true
#   value     = "${azurerm_redis_cache.redis.secondary_access_key}"
# }

