param webAppName string = uniqueString(resourceGroup().id)
param sku string = 'P1v3'
param linuxFxVersion string = 'DOCKER|asphyticz/marvelo:68'
param location string = resourceGroup().location
param dockerRegistryUrl string = 'https://index.docker.io'
param dockerRegistryUsername string = 'asphyticz'
param vnetname string = 'MarveloVNET'
param appSubnetPrefix string = '10.0.0.0/26'
param appSubnetName string = 'AppSubnet'
param appServiceKind string = 'app,linux,container'

@secure()
param dockerRegistryPassword string

var appServicePlanName = toLower('MarveloASP-${webAppName}')
var webSiteName = toLower('MarveloWeb-${webAppName}')

//Creation of App Service Plan to host the app service
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: {
    Name: 'Marvelo App Service Plan'
    BelongsTo: 'App Service'
  }
  sku: {
    name: sku
    tier: 'PremiumV3'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
    zoneRedundant: false
  }
}
//Creation of the app service
//It will also pull the image specified in the template
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: webSiteName
  location: location
  tags: {
    Name: 'Marvelo App Service'
    BelongsTo: 'App Service'
  }
  kind: appServiceKind
  identity: {
    type:'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: appSubnet.id
    siteConfig: {
      localMySqlEnabled:false
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: dockerRegistryUrl
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: dockerRegistryUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: dockerRegistryPassword
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
    }
  }
}
//Reference Existing VNET
resource MarveloVNET 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetname
}
//Create appSubnet for App Service and enable VNET Integration
resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: appSubnetName
  parent: MarveloVNET
  properties: {
    addressPrefix: appSubnetPrefix
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
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



