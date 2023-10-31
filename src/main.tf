locals {
  create_accepter = var.accepter != null

  requester_vnet_id   = var.requester.data.infrastructure.id
  requester_vnet_name = element(split("/", local.requester_vnet_id), index(split("/", local.requester_vnet_id), "virtualNetworks") + 1)
  requester_vnet_rg   = element(split("/", local.requester_vnet_id), index(split("/", local.requester_vnet_id), "resourceGroups") + 1)

  accepter_vnet_id   = try(var.accepter.data.infrastructure.id, var.accepter_vnet_id)
  accepter_vnet_name = element(split("/", local.accepter_vnet_id), index(split("/", local.accepter_vnet_id), "virtualNetworks") + 1)
  accepter_vnet_rg   = element(split("/", local.accepter_vnet_id), index(split("/", local.accepter_vnet_id), "resourceGroups") + 1)
}

data "azurerm_virtual_network" "requester" {
  name                = local.requester_vnet_name
  resource_group_name = local.requester_vnet_rg
}

data "azurerm_virtual_network" "accepter" {
  name                = local.accepter_vnet_name
  resource_group_name = local.accepter_vnet_rg
}

resource "azurerm_virtual_network_peering" "requester" {
  name                         = "${local.requester_vnet_name}-peering"
  resource_group_name          = local.requester_vnet_rg
  virtual_network_name         = local.requester_vnet_name
  remote_virtual_network_id    = local.accepter_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # allow_gateway_transit must be set to false for vnet Global Peering
  allow_gateway_transit = false

  triggers = {
    remote_address_space = join(",", data.azurerm_virtual_network.accepter.address_space)
  }
}

resource "azurerm_virtual_network_peering" "accepter" {
  count                        = local.create_accepter ? 1 : 0
  name                         = "${local.accepter_vnet_name}-peering"
  resource_group_name          = local.accepter_vnet_rg
  virtual_network_name         = local.accepter_vnet_name
  remote_virtual_network_id    = local.requester_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # allow_gateway_transit must be set to false for vnet Global Peering
  allow_gateway_transit = false

  triggers = {
    remote_address_space = join(",", data.azurerm_virtual_network.requester.address_space)
  }
}
