// Bicep taken from https://docs.microsoft.com/en-us/azure/mysql/quickstart-create-mysql-server-database-using-bicep?tabs=PowerShell
// Slight modifications done to suite project needs

@description('Server Name for Azure database for MySQL')
param serverName string = 'marvelomysql'

@description('Database administrator login name')
@minLength(1)
param administratorLogin string = 'marveloadmin'

@description('Database administrator password')
@minLength(8)
@secure()
param dbLoginPwd string

@description('Azure database for MySQL compute capacity in vCores (2,4,8,16,32)')
param skuCapacity int = 2

@description('Azure database for MySQL sku name ')
param skuName string = 'GP_Gen5_2'

@description('Azure database for MySQL Sku Size ')
param SkuSizeMB int = 5120

@description('Azure database for MySQL pricing tier')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param SkuTier string = 'GeneralPurpose'

@description('Azure database for MySQL sku family')
param skuFamily string = 'Gen5'

@description('MySQL version')
param mysqlVersion string = '8.0'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('MySQL Server backup retention days')
param backupRetentionDays int = 7

@description('Geo-Redundant Backup setting')
param geoRedundantBackup string = 'Disabled'

@description('Existing VNET Name')
param existingVNETName string = 'MarveloVNET'

@description('Existing Subnet Name')
param existingSubnetName string = 'DBSubnet'

// Referencing Existing Resources
resource existingVNET 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: existingVNETName
}

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: existingSubnetName
  parent: existingVNET
}

// Creation of the DB Server
resource mysqlDbServer 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: SkuTier
    capacity: skuCapacity
    size: '${SkuSizeMB}'  //a string is expected here but a int for the storageProfile...
    family: skuFamily
  }
  properties: {
    createMode: 'Default'
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: dbLoginPwd
    minimalTlsVersion: 'TLS1_2'
    infrastructureEncryption:'Disabled'
    publicNetworkAccess: 'Disabled'
    sslEnforcement: 'Enabled'
    storageProfile: {
      storageMB: SkuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}
//Private Endpoint Variables
@description('Private Endpoint Name')
param privateEndpointName string = 'dbPrivateEP'
@description('Private DNS Zone Name')
param privateDNSZoneName string = 'privatelink.mysql.database.azure.com'

var pvtEndpointDnsGroupName = '${privateEndpointName}/mydnsgroupname'
//Creation of Private Endpoint and Private DNS Zone
//It will then link them together
resource privateEP 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: existingSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: mysqlDbServer.id
          groupIds: [
            'mysqlserver'
          ]
        }
      }
    ]
  }
  tags: {
    Name: 'DB Private Endpoint'
  }
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZoneName
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    privateEP
  ]
}

resource privateDNSZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDNSZone
  name: '${privateDNSZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: existingVNET.id
    }
  }
}

resource privateEPDNSGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: pvtEndpointDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDNSZoneName
        properties: {
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateEP
  ]
}
