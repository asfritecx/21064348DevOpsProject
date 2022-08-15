@description('Location for all resources.')
param location string = 'japaneast'

//Variables for VNET
param vnetname string = 'MarveloVNET'
param vnetAddressPrefix string = '10.0.0.0/16'

//variables for Subnet
param dbSubnetPrefix string = '10.0.1.0/24'
param dbSubnetName string = 'DBSubnet'
param jumphostSubnetPrefix string = '10.0.2.0/26'
param jumphostSubnetName string = 'JumphostSubnet'
param appGWSubnetPrefix string = '10.0.200.0/26'
param appGWSubnetName string = 'AppGWSubnet'


var subnets = [
  {
    name: dbSubnetName
    subnetPrefix: dbSubnetPrefix
    
  }
  {
    name: appGWSubnetName
    subnetPrefix: appGWSubnetPrefix
  }
  {
    name: jumphostSubnetName
    subnetPrefix: jumphostSubnetPrefix
  }
]

//Creation Of Virtual Network
resource MarveloVNET 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes:[
        vnetAddressPrefix
      ]
    }
  }
}

//Subnet creations it will take in the subnets array and create the subnets one by one instead of parallel
@batchSize(1)
resource Subnets 'Microsoft.Network/virtualNetworks/subnets@2022-01-01'= [for (sn,index) in subnets: {
  name: sn.name
  parent: MarveloVNET
  properties: {
    addressPrefix: sn.subnetPrefix
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
    ]
  }
}]
