param bastionName string = 'MarveloBastion'
param location string = resourceGroup().location
param vnetname string = 'MarveloVNET'

// Create The Bastion Host
resource marveloBastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastionName
  location: location
  tags: {
    BelongsTo: bastionName
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    disableCopyPaste: false
    enableFileCopy: true
    enableShareableLink: true
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'BastionIPConfig'
        properties: {
          publicIPAddress: {
            id: CreateBastionPublicIP.id
          }
          subnet: {
            id: BastionSubnet.id
          }
        }
      }
    ]
    scaleUnits: 2
  }
}

param bastionSubnetName string = 'AzureBastionSubnet'
param bastionSubnetPrefix string = '10.0.210.0/26'

//Reference Existing VNET
resource MarveloVNET 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetname
}
//Create Bastion Subnet
resource BastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: bastionSubnetName
  parent: MarveloVNET
  properties: {
    addressPrefix: bastionSubnetPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    serviceEndpoints: [
      {
        locations: [
          location
        ]
        service: 'Microsoft.Sql'
      }
      {
        locations: [
          location
        ]
        service: 'Microsoft.Storage'
      }
      {
        locations: [
          location
        ]
        service: 'Microsoft.Web'
      }
      {
        locations: [
          location
        ]
        service: 'Microsoft.KeyVault'
      }
    ]
  }
}

var BastionPublicIPName = '${bastionName}-publicIP'

resource CreateBastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: BastionPublicIPName
  location: location
  tags:{
    BelongsTo: bastionName
  }
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAddressVersion:'IPv4'
    publicIPAllocationMethod:'Static'
  }
}

//Creation of the JumpHost VM
//This section of code will reference the createVM.Bicep located within the folder
@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

module DeployVM 'createVM.bicep' = {
  name: 'DeployVM'
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}
