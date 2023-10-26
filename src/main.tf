locals {
  create_accepter = var.accepter_vnet_id != null ? true : false

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

data "azurerm_virtual_network" "md-accepter" {
  count               = local.create_accepter ? 1 : 0
  name                = local.accepter_vnet_name
  resource_group_name = local.accepter_vnet_rg
}

data "azurerm_virtual_network" "external-accepter" {
  count               = local.create_accepter ? 0 : 1
  name                = element(split("/", var.accepter_vnet_id), index(split("/", var.accepter_vnet_id), "virtualNetworks") + 1)
  resource_group_name = element(split("/", var.accepter_vnet_id), index(split("/", var.accepter_vnet_id), "resourceGroups") + 1)
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
    remote_address_space = join(",", try(data.azurerm_virtual_network.md-accepter.0.address_space, data.azurerm_virtual_network.external-accepter.0.address_space))
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
