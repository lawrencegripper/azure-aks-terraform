# // These outputs can be used to deploy the monitoring Daemonset into your k8s cluster
# // https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-monitor
# output "cluster_details_client_cert" {
#   value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)}"
# }

# output "cluster_details_client_key" {
#   value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)}"
# }

# output "cluster_details_ca" {
#   value = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)}"
# }


output "kubeconfig_1" {
  sensitive = true
  value = "${module.aks_cluster_1.kube_config_data["kube_config_raw"]}"
}

output "jumpbox_network_1" {
  value = "${module.aks_cluster_1_jumpbox.ssh_command}"
}

output "kubeconfig_2" {
  sensitive = true
  value = "${module.aks_cluster_2.kube_config_data["kube_config_raw"]}"
}