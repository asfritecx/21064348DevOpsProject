// This does not work as was trying to test accessing the docker password stored in azure keyvault however it keeps failing
// Please do not use this 

param webAppName string = uniqueString(resourceGroup().id)
param sku string = 'P1v3'
param linuxFxVersion string = 'DOCKER|asphyticz/marvelo:68'
param location string = resourceGroup().location
param dockerRegistryUrl string = 'https://index.docker.io'
param dockerRegistryUsername string = 'asphyticz'

param subscriptionId string = 'e3cb207f-6802-441b-ba9c-cd52d0c74a35'
param keyVaultRG string = 'keyvaultrg'
param keyVaultName string = 'jason1253634'

resource marveloKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(subscriptionId, keyVaultRG)
}

module deployAppService './AppService.bicep' = {
  name: 'deployAppService'
  params: {
    webAppName: webAppName
    sku: sku
    linuxFxVersion: linuxFxVersion
    dockerRegistryUrl: dockerRegistryUrl
    dockerRegistryUsername: dockerRegistryUsername
    location: location
    dockerRegistryPassword: marveloKeyVault.getSecret('DockerAccessToken')
  }
}
