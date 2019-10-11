
resource "azurerm_resource_group" "k8" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_network_security_group" "k8" {
  name                = "kubernetes-nsg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  security_rule {
    name                       = "kubernetes-allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "kubernetes-allow-api-server"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = ["azurerm_virtual_network.k8"]
}

resource "azurerm_subnet_network_security_group_association" "k8" {
  subnet_id                 = "${azurerm_subnet.k8.id}"
  network_security_group_id = "${azurerm_network_security_group.k8.id}"
  depends_on = ["azurerm_subnet.k8"]
 }

resource "azurerm_virtual_network" "k8" {
 name                = "kubernetes-vnet"
 address_space       = ["10.240.0.0/24"]
 location            = "${var.location}"
 resource_group_name = "${var.resource_group_name}"
 depends_on          = ["azurerm_resource_group.k8"]
 }

resource "azurerm_subnet" "k8" {
 name                 = "kubernetes-subnet"
 resource_group_name  = "${var.resource_group_name}"
 virtual_network_name = "${azurerm_virtual_network.k8.name}"
 address_prefix       = "10.240.0.0/24"
}

resource "azurerm_route_table" "k8" {
  count = "${var.count_worker}"
  name                          = "kubernetes-routes"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  disable_bgp_route_propagation = false
  route {
    name           = "kubernetes-pods-route"
    address_prefix = "10.200.${count.index}.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.240.0.2${count.index}"
  }
  depends_on = ["azurerm_virtual_machine.workervms"]
}
resource "azurerm_subnet_route_table_association" "k8" {
  count         = "${var.count_worker}"
  subnet_id      = "${azurerm_subnet.k8.id}"
  route_table_id = "${element(azurerm_route_table.k8.*.id,count.index)}"
  depends_on = ["azurerm_route_table.k8"]
}
#resource "azurerm_subnet_route_table_association" "k81" {
#  count         = "${var.count_worker}"
#  subnet_id      = "${azurerm_subnet.k8.id}"
#  route_table_id = "${azurerm_route_table.k8.1.id}"
#  depends_on = ["azurerm_route_table.k8.1.id"]
#}
#resource "azurerm_subnet_route_table_association" "k82" {
#  count         = "${var.count_worker}"
#  subnet_id      = "${azurerm_subnet.k8.id}"
#  route_table_id = "${azurerm_route_table.k8.2.id}"
#  depends_on = ["azurerm_route_table.k8.2.id"]
#}

resource "azurerm_public_ip" "k8" {
 name                         = "KUBERNETES_PUBLIC_IP_ADDRESS"
 location                     = "${var.location}"
 resource_group_name          = "${var.resource_group_name}"
 allocation_method            = "Static"
 depends_on          = ["azurerm_resource_group.k8"]
 }
resource "azurerm_public_ip" "controller-pip" {
 count                        = "${var.count_controller}"
 name                         = "controller-${count.index}-pip"
 location                     = "${var.location}"
 resource_group_name          = "${var.resource_group_name}"
 allocation_method            = "Static"
 depends_on          = ["azurerm_resource_group.k8"]
 }
 resource "azurerm_public_ip" "worker-pip" {
 count                        = "${var.count_worker}"
 name                         = "worker-${count.index}-pip"
 location                     = "${var.location}"
 resource_group_name          = "${var.resource_group_name}"
 allocation_method            = "Static"
 depends_on          = ["azurerm_resource_group.k8"]
 }

resource "azurerm_lb" "k8" {
 name                = "kubernetes-lb"
 location            = "${var.location}"
 resource_group_name = "${var.resource_group_name}"
 frontend_ip_configuration {
   name                 = "kubernetes-pip"
   public_ip_address_id = "${azurerm_public_ip.k8.id}"
 }
}

resource "azurerm_lb_backend_address_pool" "k8" {
 resource_group_name = "${var.resource_group_name}"
 loadbalancer_id     = "${azurerm_lb.k8.id}"
 name                = "kubernetes-lb-pool"
}

resource "azurerm_lb_probe" "k8" {
 resource_group_name = "${var.resource_group_name}"
 loadbalancer_id     = "${azurerm_lb.k8.id}"
 name                = "kubernetes-apiserver-probe"
 port                = "${var.port_apiserver}"
 protocol            = "Tcp"

}

resource "azurerm_lb_rule" "k8" {
   resource_group_name            = "${var.resource_group_name}"
   loadbalancer_id                = "${azurerm_lb.k8.id}"
   name                           = "kubernetes-apiserver-probe"
   protocol                       = "Tcp"
   frontend_port                  = "${var.port_apiserver}"
   backend_port                   = "${var.port_apiserver}"
   backend_address_pool_id        = "${azurerm_lb_backend_address_pool.k8.id}"
   frontend_ip_configuration_name = "kubernetes-pip"
   probe_id                       = "${azurerm_lb_probe.k8.id}"
}

resource "azurerm_network_interface" "controller-nic" {
 count               = "${var.count_controller}"
 name                = "controller-${count.index}-nic"
 location            = "${var.location}"
 resource_group_name = "${var.resource_group_name}"
 enable_ip_forwarding = true
 ip_configuration {
   name                          = "controller-${count.index}-ip"
   subnet_id                     = "${azurerm_subnet.k8.id}"
   private_ip_address            = "10.240.0.1${count.index}"
   private_ip_address_allocation = "Static"
   #load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.k8.id}"]
   public_ip_address_id = "${length(azurerm_public_ip.controller-pip.*.id) > 0 ? element(concat(azurerm_public_ip.controller-pip.*.id, list("")), count.index) : ""}"
}
depends_on = ["azurerm_public_ip.controller-pip"]
}

resource "azurerm_network_interface_backend_address_pool_association" "k8" {
  count = "${var.count_controller}"
  network_interface_id = "${element(azurerm_network_interface.controller-nic.*.id,count.index)}"
  ip_configuration_name = "controller-${count.index}-ip"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.k8.id}"
}

resource "azurerm_network_interface" "worker-nic" {
 count               = "${var.count_worker}"
 name                = "worker-${count.index}-nic"
 location            = "${var.location}"
 resource_group_name = "${var.resource_group_name}"
 enable_ip_forwarding = true
 ip_configuration {
   name                          = "worker-${count.index}-ip"
   subnet_id                     = "${azurerm_subnet.k8.id}"
   private_ip_address            = "10.240.0.2${count.index}"
   private_ip_address_allocation = "Static"
   public_ip_address_id = "${length(azurerm_public_ip.worker-pip.*.id) > 0 ? element(concat(azurerm_public_ip.worker-pip.*.id, list("")), count.index) : ""}"
 }
 depends_on = ["azurerm_public_ip.worker-pip"]
}

resource "azurerm_availability_set" "controller-as" {
 name                         = "controller-as"
 location                     = "${var.location}"
 resource_group_name          = "${var.resource_group_name}"
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
 depends_on          = ["azurerm_resource_group.k8"]
}

resource "azurerm_availability_set" "worker-as" {
 name                         = "worker-as"
 location                     = "${var.location}"
 resource_group_name          = "${var.resource_group_name}"
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
 depends_on          = ["azurerm_resource_group.k8"]
}

resource "azurerm_virtual_machine" "controllervms" {
  count = "${var.count_controller}"
  name                  = "controller-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  availability_set_id = "${azurerm_availability_set.controller-as.id}"
  network_interface_ids = ["${element(azurerm_network_interface.controller-nic.*.id, count.index)}"]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "controllerosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "controller-${count.index}"
    admin_username = "kuberoot"
    
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
            path     = "/home/kuberoot/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCs5fvXGe19OYcAZc/r0RUW4QIX9AjerwZQA1m8xfya104RdSK7YfCus83lBkBKzUWn3peGMBMlxTljSmlp8uINWeNWPAYOecFsVlmM2h9PR4K8HApWNJEIu4B0TP78gyCZ9OzSL1eWvCmUMOd5IujHk6TphUHKT+nMbRzfECdnGXlX+EJCiS6+u2eNNZ6AobR6v+kHvw/t5AgekyrJ0gNYWWl+jwL5ffDx63WAZzYcToPnWqiC34IBC4xsFCLl0qpB75Ct1Ix5Y1EBGYxFWNqXakSDNi8d1A1fGkVaR4QVtikM37XnDveBMkN38sodLT+Nx2TkULqt6tGk87AhVdSr arun@arukum"
        }
  }
}

resource "azurerm_virtual_machine" "workervms" {
  count                 = "${var.count_worker}"
  name                  = "worker-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  availability_set_id   = "${azurerm_availability_set.worker-as.id}"
  network_interface_ids = ["${element(azurerm_network_interface.worker-nic.*.id, count.index)}"]
  vm_size               = "Standard_B1ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "workerosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "worker-${count.index}"
    admin_username = "kuberoot"
    
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
            path     = "/home/kuberoot/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCs5fvXGe19OYcAZc/r0RUW4QIX9AjerwZQA1m8xfya104RdSK7YfCus83lBkBKzUWn3peGMBMlxTljSmlp8uINWeNWPAYOecFsVlmM2h9PR4K8HApWNJEIu4B0TP78gyCZ9OzSL1eWvCmUMOd5IujHk6TphUHKT+nMbRzfECdnGXlX+EJCiS6+u2eNNZ6AobR6v+kHvw/t5AgekyrJ0gNYWWl+jwL5ffDx63WAZzYcToPnWqiC34IBC4xsFCLl0qpB75Ct1Ix5Y1EBGYxFWNqXakSDNi8d1A1fGkVaR4QVtikM37XnDveBMkN38sodLT+Nx2TkULqt6tGk87AhVdSr arun@arukum"
        }
  }
  tags = {
        pod-cidr = "[10.200.${count.index}.0/24]"
    }
}
output "controller-pip" {
  value = "${azurerm_public_ip.controller-pip.*.ip_address}"
}
output "worker-pip" {
  value = "${azurerm_public_ip.worker-pip.*.ip_address}"
}
## Everything is working fine, just adding a comment to commit to GitHub