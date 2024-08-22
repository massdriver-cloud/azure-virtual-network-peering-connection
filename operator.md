## Azure Virtual Network Peering

Azure Virtual Network (VNet) peering seamlessly connects two Azure virtual networks. Once peered, the virtual networks appear as one for connectivity purposes. Resources in both virtual networks can communicate with each other with the same latency and bandwidth as if they were within the same network.

### Design Decisions

1. **VNet Accepter Conditional Creation**: The module allows conditional creation of the accepter peering based on whether an accepter VNet is provided. This makes the module flexible to handle both cases where peering is initiated by the accepter VNet or already exists.
2. **Traffic Allowances**: The peering connections are configured to allow virtual network access and forwarded traffic while disabling gateway transit to ensure compliance with Global Peering restrictions.
3. **Triggers for Address Space Changes**: The module includes triggers that react to changes in the remote network's address space to ensure the peering connection remains up to date.

This bundle is tailored for two scenarios:
1. Peering two Virtual Networks, both of which are provisioned by Massdriver and in the same Azure subscription.
2. Peering two Virtual Networks, only one of which is provisioned and managed by Massdriver.

#### Both Virtual Networks in the Same Subscription Provisioned by Massdriver
In this case, both Virtual Networks are managed by Massdriver and are in the same Azure subscription. Users should connect both Virtual Networks to the bundle (one to `accepter` and the other to `requester`). It doesn't matter which network is the accepter or requester; they are functionally equivalent. The bundle will handle all the necessary configurations, including establishing the peering connection and syncing the connection.

#### Virtual Networks in Separate Subscriptions, or Only One Managed by Massdriver
In this case, the bundle will use the `requester` connection only. You'll need to specify additional field for "Remote Virtual Network ID" to initiate the peering correctly. No additional manual steps will be necessary in the Azure portal to complete the peering process.

**Steps to Manually Accept Peering Connection**:
1. Log into the Azure portal for the `accepter` subscription.
2. Navigate to the Virtual Network Overview page.
3. Choose `JSON View` in the top right corner.
4. Copy the `id` value near the top (without quotes). For example: `/subscriptions/123456-1234-1234-1234-12345678/resourceGroups/foo-bar/providers/Microsoft.Network/virtualNetworks/foo-var-vnet`
5. Paste the `id` into the `Remote Virtual Network ID` field in the bundle and deploy
6. Navigate to the Virtual Network Peerings page.
7. Click on the peering connection.
8. Click `Resync` and `Save`.

### FAQ

#### Can my address spaces overlap?
No, they cannot overlap. By default, the Azure Virtual Network bundle uses our Auto-CIDR feature to provision your VNet and using an address space that does not overlap with any other address space for any other VNet in the same subscription. If you are using a custom CIDR, you will need to ensure that the address spaces do not overlap.

If you are peering your VNet to a VNet that is not managed by Massdriver, you'll need to ensure that the address space for each VNet does not overlap.

#### I'm trying to peer VNets across subscriptions, but I'm getting an error.
If you are peering VNets across subscriptions, you'll need to ensure that [Microsoft Entra B2B collaboration](https://learn.microsoft.com/en-us/azure/active-directory/external-identities/add-users-administrator?toc=/azure/virtual-network/toc.json#add-guest-users-to-the-directory) is configured.

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

