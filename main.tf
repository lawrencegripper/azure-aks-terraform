resource "azurerm_resource_group" "cluster" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

## Create an OMS workspace to use for logging

module "oms" {
  source = "oms"

  resource_group_name     = "${azurerm_resource_group.cluster.name}"
  resource_group_location = "${var.resource_group_location}"
}

## Create the first network and cluster

resource azurerm_network_security_group "sercurity_group_cluster_1" {
  name                = "akc-1-nsg"
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
}

resource "azurerm_virtual_network" "network_cluster_1" {
  name                = "akc-1-vnet"
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet_cluster_1" {
  name                      = "akc-1-subnet"
  resource_group_name       = "${azurerm_resource_group.cluster.name}"
  network_security_group_id = "${azurerm_network_security_group.sercurity_group_cluster_1.id}"
  address_prefix            = "10.1.0.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network_cluster_1.name}"
}

module "aks_cluster_1" {
  source = "aks_cluster"

  cluster_name_prefix = "cluster1"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  location            = "${var.resource_group_location}"

  kubetnetes_version = "${var.kubetnetes_version}"
  vm_size            = "${var.vm_size}"
  node_count         = "${var.node_count}"

  linux_admin_username      = "${var.linux_admin_username}"
  linux_admin_ssh_publickey = "${var.linux_admin_ssh_publickey}"

  subnet_id = "${azurerm_subnet.subnet_cluster_1.id}"
  oms_id    = "${module.oms.id}"
}

## Create the second network and cluster

resource azurerm_network_security_group "sercurity_group_cluster_2" {
  name                = "aks-2-nsg"
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
}

resource "azurerm_virtual_network" "network_cluster_2" {
  name                = "aks-2-vnet"
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "subnet_cluster_2" {
  name                      = "aks-2-subnet"
  resource_group_name       = "${azurerm_resource_group.cluster.name}"
  network_security_group_id = "${azurerm_network_security_group.sercurity_group_cluster_1.id}"
  address_prefix            = "10.2.0.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network_cluster_1.name}"
}

module "aks_cluster_2" {
  source = "aks_cluster"

  cluster_name_prefix = "cluster2"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  location            = "${var.resource_group_location}"

  kubetnetes_version = "${var.kubetnetes_version}"
  vm_size            = "${var.vm_size}"
  node_count         = "${var.node_count}"

  linux_admin_username      = "${var.linux_admin_username}"
  linux_admin_ssh_publickey = "${var.linux_admin_ssh_publickey}"

  subnet_id = "${azurerm_subnet.subnet_cluster_2.id}"
  oms_id    = "${module.oms.id}"
}

## Peer networks 

resource "azurerm_virtual_network_peering" "peer1" {
  name                         = "aks-peer-cluster1to2"
  resource_group_name          = "${azurerm_resource_group.cluster.name}"
  virtual_network_name         = "${azurerm_virtual_network.network_cluster_1.name}"
  remote_virtual_network_id    = "${azurerm_virtual_network.network_cluster_2.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "peer2" {
  name                         = "aks-peer-cluster2to1"
  resource_group_name          = "${azurerm_resource_group.cluster.name}"
  virtual_network_name         = "${azurerm_virtual_network.network_cluster_2.name}"
  remote_virtual_network_id    = "${azurerm_virtual_network.network_cluster_1.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
