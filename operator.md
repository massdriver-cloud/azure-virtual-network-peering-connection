## Azure Virtual Network Peering

Azure Virtual Network (VNet) peering seamlessly connects two Azure virtual networks. Once peered, the virtual networks appear as one for connectivity purposes. Resources in both virtual networks can communicate with each other with the same latency and bandwidth as if they were within the same network.

### Design Decisions

1. **VNet Accepter Conditional Creation**: The module allows conditional creation of the accepter peering based on whether an accepter VNet is provided. This makes the module flexible to handle both cases where peering is initiated by the accepter VNet or already exists.
2. **Traffic Allowances**: The peering connections are configured to allow virtual network access and forwarded traffic while disabling gateway transit to ensure compliance with Global Peering restrictions.
3. **Triggers for Address Space Changes**: The module includes triggers that react to changes in the remote network's address space to ensure the peering connection remains up to date.

### Runbook

#### Troubleshooting VNet Peering Status

If you're having issues with connectivity, the first step is to check the peering status.

Check the status using Azure CLI:

```sh
az network vnet peering show --name <peering-name> --resource-group <resource-group> --vnet-name <vnet-name>
```

You should see a status of `Connected` if the peering has been successfully established.

#### Debugging Peering Connectivity Issues

If the status indicates an issue, you may need to check security rules and routes.

Verify effective routes in requester VNet:

```sh
az network vnet list-effective-routes --name <requester-vnet-name> --resource-group <requester-resource-group>
```

Verify effective routes in accepter VNet:

```sh
az network vnet list-effective-routes --name <accepter-vnet-name> --resource-group <accepter-resource-group>
```

Ensure that there are routes allowing traffic between the VNets.

#### Validating Network Security Groups (NSGs)

NSGs might block traffic between peered VNets. Verify NSGs using Azure CLI:

```sh
az network nsg show --name <nsg-name> --resource-group <resource-group>
```

Check inbound and outbound security rules to make sure they allow traffic between the subnets in the peered VNets.

#### Checking Azure Network Watcher

Use Azure Network Watcher to diagnose connectivity issues.

Initiate a connectivity check:

```sh
az network watcher test-connectivity --source-resource <source-resource-id> --dest-resource <dest-resource-id>
```

This command helps identify where traffic is blocked along the network path.

#### Diagnosing DNS Resolution Issues

If services within peered VNets cannot resolve each other via DNS, ensure both VNets are configured for DNS resolution.

Verify DNS settings:

```sh
az network vnet show --name <vnet-name> --resource-group <resource-group> --query "dhcpOptions.dnsServers"
```

Ensure that both VNets are configured to use the appropriate DNS servers.

