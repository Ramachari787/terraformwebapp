# I have taken Azurerm as providers to deploy the resources on Azure cloud
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
#Configure the microsoft provider
provider "azurerm" {
    features {}
}


#Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.rglocation}"
}

#create virtual network within the resource group 
resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.vnet_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  address_space       = [var.vnet_cidr_prefix]
  
}

#Create web subnet within the above Vnet
resource "azurerm_subnet" "websubnet" {
  name                 = "${var.websubnet}"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = [var.websubnet_cidr_prefix]
}

#Create app subnet within the above Vnet
resource "azurerm_subnet" "appsubnet" {
  name                 = "${var.appsubnet}"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = [var.appsubnet_cidr_prefix]
}

#Create DB subnet within the above Vnet
resource "azurerm_subnet" "DBsubnet" {
  name                 = "${var.DBsubnet}"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = [var.DBsubnet_cidr_prefix]
}

#Create jumphost subnet within the above Vnet
resource "azurerm_subnet" "jumpsubnet" {
  name                 = "${var.jumpsubnet}"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = [var.jumpsubnet_cidr_prefix]
}

resource "azurerm_public_ip" "web_pubip" {
  name                = "${var.web_pub_ip}-PubIP"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
  #tags                = var.tags
}

resource "azurerm_network_interface" "webnic" {
  name                = "${var.web_nic_prefix}-nic"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.websubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.web_pubip.id
  }
}

#create network security group with *nsg1 as a prefix
resource "azurerm_network_security_group" "web" {
  name                = "${var.websubnet}-nsg"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  security_rule {
    name                       = "allow_80_sg"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [ "80", "8080" , "22"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_443_sg"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "8443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "prod"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  subnet_id                 = azurerm_subnet.websubnet.id
  network_security_group_id = azurerm_network_security_group.web.id
}



resource "azurerm_linux_virtual_machine" "nginxwebvm" {
  name                            = "${var.webserver_name}web-01"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "${var.web_vm_size}"
  admin_username                  = "${var.vm_username}"
  admin_password                  = "12345"
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.webnic.id ]

 

  source_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  os_disk {
    storage_account_type = "${var.storage_account_type}"
    caching              = "${var.disk_caching}"
  }
}


resource "azurerm_network_interface" "appnic1" {
  name                = "${var.app_nic_prefix}app-nic1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.appsubnet.id
    private_ip_address_allocation = "Dynamic"
    ###public_ip_address_id = azurerm_public_ip.nginxweb_pubip.id
  }
}

#create network security group with *nsg1 as a prefix
resource "azurerm_network_security_group" "app" {
  name                = "${var.appsubnet}-nsg"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  security_rule {
    name                       = "allow_80_sg"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [ "80", "8080" , "22"]
    source_address_prefix      = "${var.vnet_cidr_prefix}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_443_sg"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "8443"]
    source_address_prefix      = "${var.vnet_cidr_prefix}"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "qa"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_appsubnet_assoc" {
  subnet_id                 = azurerm_subnet.appsubnet.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_linux_virtual_machine" "appvm1" {
  name                            = "${var.appserver_name}app-01"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "${var.app_vm_size}"
  admin_username                  = "${var.vm_username}"
  admin_password                  = "12345"
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.appnic1.id ]


  source_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  os_disk {
    storage_account_type = "${var.storage_account_type}"
    caching              = "${var.disk_caching}"
  }
}

resource "azurerm_network_interface" "appnic2" {
  name                = "${var.app_nic_prefix}app-nic2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.appsubnet.id
    private_ip_address_allocation = "Dynamic"
    ###public_ip_address_id = azurerm_public_ip.nginxweb_pubip.id
  }
}

resource "azurerm_linux_virtual_machine" "appvm2" {
  name                            = "${var.appserver_name}app-02"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "${var.app_vm_size}"
  admin_username                  = "${var.vm_username}"
  admin_password                  = "12345"
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.appnic2.id ]



  source_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  os_disk {
    storage_account_type = "${var.storage_account_type}"
    caching              = "${var.disk_caching}"
  }
}

resource "azurerm_network_interface" "dbnic" {
  name                = "${var.db_nic_prefix}db-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.DBsubnet.id
    private_ip_address_allocation = "Dynamic"
    ###public_ip_address_id = azurerm_public_ip.nginxweb_pubip.id
  }
}

#create network security group with *nsg1 as a prefix
resource "azurerm_network_security_group" "db" {
  name                = "${var.DBsubnet}-nsg"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  security_rule {
    name                       = "allow_80_sg"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [ "80", "8080" , "22"]
    source_address_prefix      = "${var.vnet_cidr_prefix}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_443_sg"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "8443"]
    source_address_prefix      = "${var.vnet_cidr_prefix}"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "prod"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_dbsubnet_assoc" {
  subnet_id                 = azurerm_subnet.DBsubnet.id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_linux_virtual_machine" "dbvm1" {
  name                            = "${var.dbserver_name}db-01"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "${var.db_vm_size}"
  admin_username                  = "${var.vm_username}"
  admin_password                  = "123456"
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.dbnic.id ]

  

  source_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  os_disk {
    storage_account_type = "${var.storage_account_type}"
    caching              = "${var.disk_caching}"
  }
}

resource "azurerm_public_ip" "jump_pubip" {
  name                = "${var.jump_pub_ip}-PubIP"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
  #tags                = var.tags
}

resource "azurerm_network_interface" "jumpnic" {
  name                = "${var.jump_nic_prefix}jump-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jumpsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.jump_pubip.id
  }
}

#create network security group with *nsg1 as a prefix
resource "azurerm_network_security_group" "jump" {
  name                = "${var.jumpsubnet}-nsg"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"

  security_rule {
    name                       = "allow_80_sg"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [ "80", "8080" , "22"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "prod"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_jumpsubnet_assoc" {
  subnet_id                 = azurerm_subnet.jumpsubnet.id
  network_security_group_id = azurerm_network_security_group.jump.id
}

resource "azurerm_linux_virtual_machine" "jumphostvm" {
  name                            = "${var.jumpserver_name}jumpserver"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "${var.jump_vm_size}"
  admin_username                  = "${var.vm_username}"
  network_interface_ids = [ azurerm_network_interface.jumpnic.id ]

  

  source_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  os_disk {
    storage_account_type = "${var.storage_account_type}"
    caching              = "${var.disk_caching}"
  }
}

output "jump_public_ip" {
  value = azurerm_public_ip.jump_pubip.ip_address
}
