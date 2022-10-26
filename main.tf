terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "jma-rg" {
  name     = "jma-resources"
  location = "East Us"
  tags = {
    environment = "jec"
  }
}


resource "azurerm_virtual_network" "jma-vn" {
  name                = "jma-network"
  resource_group_name = azurerm_resource_group.jma-rg.name
  location            = azurerm_resource_group.jma-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "jec"
  }
}

resource "azurerm_subnet" "jma-subnet" {
  name                 = "jma-subnet"
  resource_group_name  = azurerm_resource_group.jma-rg.name
  virtual_network_name = azurerm_virtual_network.jma-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "jma-sg" {
  name                = "jma-sg"
  location            = azurerm_resource_group.jma-rg.location
  resource_group_name = azurerm_resource_group.jma-rg.name

  tags = {
    environment = "jec"
  }
}

resource "azurerm_network_security_rule" "jma-dev-rule" {
  name                        = "-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.jma-rg.name
  network_security_group_name = azurerm_network_security_group.jma-sg.name
}

resource "azurerm_public_ip" "jma-ip" {
  name                = "jma-ip"
  resource_group_name = azurerm_resource_group.jma-rg.name
  location            = azurerm_resource_group.jma-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "jec"
  }
}

resource "azurerm_network_interface" "jma-nic" {
  name                = "jma-nic"
  location            = azurerm_resource_group.jma-rg.location
  resource_group_name = azurerm_resource_group.jma-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jma-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jma-ip.id
  }

  tags = {
    environment = "jec"
  }
}

resource "azurerm_linux_virtual_machine" "jma-vm" {
  name                  = "jma-vm"
  resource_group_name   = azurerm_resource_group.jma-rg.name
  location              = azurerm_resource_group.jma-rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.jma-nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("D:/terraform-azj/myDemo/mykeyjec1.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

