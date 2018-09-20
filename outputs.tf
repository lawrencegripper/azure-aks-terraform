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

output "jumpbox_network_2" {
  value = "${module.aks_cluster_2_jumpbox.ssh_command}"
}