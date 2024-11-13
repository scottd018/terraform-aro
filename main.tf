locals {
  name_prefix = var.cluster_name
  pull_secret = var.pull_secret_path != null && var.pull_secret_path != "" ? file(var.pull_secret_path) : null
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = var.tags
}

## Network resources
resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.aro_virtual_network_cidr_block]
  tags                = var.tags

}

resource "azurerm_subnet" "control_plane_subnet" {
  name                                          = "${local.name_prefix}-cp-subnet"
  resource_group_name                           = azurerm_resource_group.main.name
  virtual_network_name                          = azurerm_virtual_network.main.name
  address_prefixes                              = [var.aro_control_subnet_cidr_block]
  service_endpoints                             = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
  private_link_service_network_policies_enabled = true
  private_endpoint_network_policies_enabled     = true
}

resource "azurerm_subnet" "machine_subnet" {
  name                 = "${local.name_prefix}-machine-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aro_machine_subnet_cidr_block]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

# resource "azurerm_network_security_group" "aro" {
#   name                = "${local.name_prefix}-nsg"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
# }

# resource "azurerm_network_security_rule" "aro_inbound" {
#   name                        = "${local.name_prefix}-inbound"
#   network_security_group_name = azurerm_network_security_group.aro.name
#   resource_group_name         = azurerm_resource_group.main.name
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
# }

# resource "azurerm_network_security_rule" "aro_outbound" {
#   name                        = "${local.name_prefix}-outbound"
#   network_security_group_name = azurerm_network_security_group.aro.name
#   resource_group_name         = azurerm_resource_group.main.name
#   priority                    = 100
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
# }

# resource "azurerm_subnet_network_security_group_association" "control_plane" {
#   subnet_id                 = azurerm_subnet.control_plane_subnet.id
#   network_security_group_id = azurerm_network_security_group.aro.id
# }

# resource "azurerm_subnet_network_security_group_association" "machine" {
#   subnet_id                 = azurerm_subnet.machine_subnet.id
#   network_security_group_id = azurerm_network_security_group.aro.id
# }

## ARO Cluster

# See docs at https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redhat_openshift_cluster

resource "azurerm_redhat_openshift_cluster" "cluster" {
  # NOTE: use the installer service principal that we created to create our cluster
  provider = azurerm.installer

  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # NOTE: this input is missing to provide parity with the old provider at 
  #       https://github.com/rh-mobb/terraform-provider-azureopenshift
  # cluster_resource_group = "${var.cluster_name}-cluster-rg"

  cluster_profile {
    domain      = var.domain
    pull_secret = local.pull_secret
    version     = var.aro_version
  }

  main_profile {
    vm_size   = var.main_vm_size
    subnet_id = azurerm_subnet.control_plane_subnet.id
  }

  worker_profile {
    subnet_id    = azurerm_subnet.machine_subnet.id
    disk_size_gb = var.worker_disk_size_gb
    node_count   = var.worker_node_count
    vm_size      = var.worker_vm_size
  }

  network_profile {
    outbound_type = var.outbound_type
    pod_cidr      = var.aro_pod_cidr_block
    service_cidr  = var.aro_service_cidr_block
    #preconfigured_nsg_enabled = true
  }

  api_server_profile {
    visibility = var.api_server_profile
  }

  ingress_profile {
    visibility = var.ingress_profile
  }

  service_principal {
    client_id     = module.aro_permissions.cluster_service_principal_client_id
    client_secret = module.aro_permissions.cluster_service_principal_client_secret
  }

  depends_on = [
    module.aro_permissions,
    azurerm_firewall_network_rule_collection.firewall_network_rules,
  ]
}
