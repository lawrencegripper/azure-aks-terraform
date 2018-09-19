
variable "kubetnetes_version" {
  type        = "string"
  description = "The k8s version to deploy eg: '1.8.5', '1.10.5' etc"
}

variable "vm_size" {
  description = "The VM_SKU to use for the agents in the cluster"
}

variable "node_count" {
  description = "The number of agents nodes to provision in the cluster"
}

variable "resource_group_name" {
  description = "The resource group name to deploy into"
}

variable "oms_workspace_id" {
  description = "The OMS ID used for container logging"
}



variable "linux_admin_username" {
  type        = "string"
  description = "User name for authentication to the Kubernetes linux agent virtual machines in the cluster."
}

variable "linux_admin_ssh_publickey" {
  type        = "string"
  description = "Configure all the linux virtual machines in the cluster with the SSH RSA public key string. The key should include three parts, for example 'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm'"
}

variable "location" {
  description = "The azure region to deploy into"
}

variable "subnet_id" {
  description = "Subnet in which to deploy AKS"
}
