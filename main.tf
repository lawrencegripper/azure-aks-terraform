resource "azurerm_resource_group" "cluster" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location[0]}"
}

## Create an OMS workspace to use for logging

module "oms" {
  source = "oms"

  resource_group_name     = "${azurerm_resource_group.cluster.name}"
  resource_group_location = "${var.resource_group_location[0]}"
}

## Create the first network and cluster

resource azurerm_network_security_group "sercurity_group_cluster_1" {
  name                = "aks-1-nsg"
  location            = "${var.resource_group_location[0]}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
}

resource "azurerm_virtual_network" "network_cluster_1" {
  name                = "aks-1-vnet"
  location            = "${var.resource_group_location[0]}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet_cluster_1" {
  name                      = "aks-1-subnet"
  resource_group_name       = "${azurerm_resource_group.cluster.name}"
  network_security_group_id = "${azurerm_network_security_group.sercurity_group_cluster_1.id}"
  address_prefix            = "10.1.0.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network_cluster_1.name}"
}

module "aks_cluster_1" {
  source = "aks_cluster"

  cluster_name_prefix = "cluster1"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  location            = "${var.resource_group_location[0]}"

  kubetnetes_version = "${var.kubetnetes_version}"
  vm_size            = "${var.vm_size}"
  node_count         = "${var.node_count}"

  linux_admin_username      = "${var.linux_admin_username}"
  linux_admin_ssh_publickey = "${var.linux_admin_ssh_publickey}"

  subnet_id = "${azurerm_subnet.subnet_cluster_1.id}"
  oms_id    = "${module.oms.id}"
}

##  Create a jumpbox in Cluster 1's vnet for debugging

resource azurerm_network_security_group "security_group_jumpbox_1" {
  name                = "aks-1-jumpbox-nsg"
  location            = "${var.resource_group_location[0]}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  
  security_rule {
    name                       = "allow-ssh"
    description                = "Allow SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}


resource "azurerm_subnet" "subnet_jumpbox_1" {
  name                      = "aks-1-jumpbox-subnet"
  resource_group_name       = "${azurerm_resource_group.cluster.name}"
  network_security_group_id = "${azurerm_network_security_group.security_group_jumpbox_1.id}"
  address_prefix            = "10.1.1.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network_cluster_1.name}"
}

module "aks_cluster_1_jumpbox" {
  source = "jumpbox"

  prefix = "aks-1-jumpbox"
  linux_admin_username      = "${var.linux_admin_username}"
  linux_admin_ssh_publickey = "${var.linux_admin_ssh_publickey}"

  resource_group_name = "${azurerm_resource_group.cluster.name}"
  location            = "${var.resource_group_location[0]}"

  subnet_id = "${azurerm_subnet.subnet_jumpbox_1.id}"
}

## Create the second network and cluster

resource azurerm_network_security_group "sercurity_group_cluster_2" {
  name                = "aks-2-nsg"
  location            = "${var.resource_group_location[1]}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
}

resource "azurerm_virtual_network" "network_cluster_2" {
  name                = "aks-2-vnet"
  location            = "${var.resource_group_location[1]}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "subnet_cluster_2" {
  name                      = "aks-2-subnet"
  resource_group_name       = "${azurerm_resource_group.cluster.name}"
  network_security_group_id = "${azurerm_network_security_group.sercurity_group_cluster_2.id}"
  address_prefix            = "10.2.0.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network_cluster_2.name}"
}

module "aks_cluster_2" {
  source = "aks_cluster"

  cluster_name_prefix = "cluster2"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  location            = "${var.resource_group_location[1]}"

  kubetnetes_version = "${var.kubetnetes_version}"
  vm_size            = "${var.vm_size}"
  node_count         = "${var.node_count}"

  linux_admin_username      = "${var.linux_admin_username}"
  linux_admin_ssh_publickey = "${var.linux_admin_ssh_publickey}"

  subnet_id = "${azurerm_subnet.subnet_cluster_2.id}"
  oms_id    = "${module.oms.id}"
}

##  Create a jumpbox in Cluster 2's vnet for debugging

resource azurerm_network_security_group "security_group_jumpbox_2" {
  name                = "aks-2-jumpbox-nsg"
  location            = "${var.resource_group_location[1]}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  
  security_rule {
    name                       = "allow-ssh"
    description                = "Allow SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}


resource "azurerm_subnet" "subnet_jumpbox_2" {
  name                      = "aks-2-jumpbox-subnet"
  resource_group_name       = "${azurerm_resource_group.cluster.name}"
  network_security_group_id = "${azurerm_network_security_group.security_group_jumpbox_2.id}"
  address_prefix            = "10.2.1.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network_cluster_2.name}"
}

module "aks_cluster_2_jumpbox" {
  source = "jumpbox"

  prefix = "jumpbox-2"
  linux_admin_username      = "${var.linux_admin_username}"
  linux_admin_ssh_publickey = "${var.linux_admin_ssh_publickey}"

  resource_group_name = "${azurerm_resource_group.cluster.name}"
  location            = "${var.resource_group_location[1]}"

  subnet_id = "${azurerm_subnet.subnet_jumpbox_2.id}"
}


## Peer networks 

resource "azurerm_virtual_network_peering" "peer1" {
  name                         = "aks-peer-cluster1to2"
  resource_group_name          = "${azurerm_resource_group.cluster.name}"
  virtual_network_name         = "${azurerm_virtual_network.network_cluster_1.name}"
  remote_virtual_network_id    = "${azurerm_virtual_network.network_cluster_2.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

   # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "peer2" {
  name                         = "aks-peer-cluster2to1"
  resource_group_name          = "${azurerm_resource_group.cluster.name}"
  virtual_network_name         = "${azurerm_virtual_network.network_cluster_2.name}"
  remote_virtual_network_id    = "${azurerm_virtual_network.network_cluster_1.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

   # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit        = false
}
