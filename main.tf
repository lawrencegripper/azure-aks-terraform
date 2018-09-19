resource "azurerm_resource_group" "cluster" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

resource azurerm_network_security_group "sercurity_group" {
  name                = "akc-1-nsg"
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
}

resource "azurerm_virtual_network" "network" {
  name                = "akc-1-vnet"
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet_cluster_1" {
  name                      = "akc-1-subnet"
  resource_group_name       = "${azurerm_resource_group.cluster.name}"
  network_security_group_id = "${azurerm_network_security_group.sercurity_group.id}"
  address_prefix            = "10.1.0.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network.name}"
}

module "oms" {
  source = "oms"

  resource_group_name     = "${azurerm_resource_group.cluster.name}"
  resource_group_location = "${var.resource_group_location}"
}

module "aks_cluster_1" {
  source = "aks_cluster"

  resource_group_name = "${azurerm_resource_group.cluster.name}"
  location = "${var.resource_group_location}"
  
  kubetnetes_version= "${var.kubetnetes_version}"
  vm_size = "${var.vm_size}"
  node_count = "${var.node_count}"

  linux_admin_username = "${var.linux_admin_username}"
  linux_admin_ssh_publickey = "${var.linux_admin_ssh_publickey}"
  
  subnet_id = "${azurerm_subnet.subnet_cluster_1.id}"
  oms_id = "${module.oms.id}"
}

