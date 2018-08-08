// These outputs can be used to deploy the monitoring Daemonset into your k8s cluster
// https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-monitor
output "cluster_details_client_cert" {
  value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)}"
}

output "cluster_details_client_key" {
  value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)}"
}

output "cluster_details_ca" {
  value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)}"
}
