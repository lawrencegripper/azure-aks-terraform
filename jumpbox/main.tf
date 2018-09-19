variable "subnet_id" {}

variable "prefix" {}

variable "resource_group_name" {}

variable "location" {}
variable "linux_admin_username" {}
variable "linux_admin_ssh_publickey" {}

resource "azurerm_public_ip" "pip" {
  name                         = "${var.prefix}-pip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id  = "${azurerm_public_ip.pip.id}"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-jumpbox-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-jumpbox"
    admin_username = "${var.linux_admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.linux_admin_username}/.ssh/authorized_keys"
      key_data = "${var.linux_admin_ssh_publickey}"
    }
  }
}

output "ssh_command" {
  value = "ssh ${var.linux_admin_username}@${azurerm_public_ip.pip.ip_address}"
}
