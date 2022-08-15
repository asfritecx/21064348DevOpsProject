param location string = 'japaneast'

@description('MarveloMYSQLDatabase Admin Password')
@secure()
param administratorLoginPassword string 

@description('Docker Password for Asphyticz Account')
@secure()
param dockerRegistryPassword string 

 @description('JumphostVM UserName')
@secure()
param jumphostVMUsername string

@description('JumphostVM Password')
@secure()
param jumphostVMPassword string 

//Deploys the Virtual Network by referencing the local bicep file
module DeployVNET '01-VNETCreation/deployVNET.bicep' = {
  name: 'DeployMarveloVNET'
  params: {
    location: location
  }
}
//Deploys the MySQL Database by referencing the local bicep file
module DeployMYSQLDatabase '02-MySQLCreation/deployMYSQL.bicep' = {
  name: 'DeployMYSQLDatabase'
  params: {
    location: location
    administratorLoginPassword: administratorLoginPassword
  }
  dependsOn: [
    DeployVNET
  ]
}
//Deploys the AppService by referencing the local bicep file
module DeployAppService '03-AppServiceCreation/AppService.bicep' = {
  name: 'DeployAppService'
  params: {
    location: location
    dockerRegistryPassword: dockerRegistryPassword
  }
  dependsOn: [
    DeployVNET
    DeployMYSQLDatabase
  ]
}

//Uncomment if need to use Bastion
module DeployBastionService '04-BastionVMCreation/bastionDeploy.bicep' = {
  name: 'DeployBastionService'
  params: {
    location: location
    adminPassword: jumphostVMPassword
    adminUsername: jumphostVMUsername
  }
  dependsOn: [
    DeployVNET
    DeployAppService
  ]
} 
