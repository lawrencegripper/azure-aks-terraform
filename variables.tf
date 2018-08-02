variable "client_id" {
  type        = "string"
  description = "Client ID"
}

variable "client_secret" {
  type        = "string"
  description = "Client secret."
}

variable "node_count" {
 default = 2 
}


variable "node_sku" {
  type = "string"
  description = "the node sku to use"
  default = "Standard_DS2_v2"
}


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

variable "linux_admin_username" {
  type        = "string"
  description = "User name for authentication to the Kubernetes linux agent virtual machines in the cluster."
}
