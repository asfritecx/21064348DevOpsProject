param location string = 'japaneast'

//Deploys the Virtual Network by referencing the local bicep file
module DeployVNET '01-VNETCreation/deployVNET.bicep' = {
  name: 'DeployMarveloVNET'
  params: {
    location: location
  }
}


@description('Database Login Password')
@secure()
param dbLoginPwd string 

//Deploys the MySQL Database by referencing the local bicep file
module DeployMYSQLDatabase '02-MySQLCreation/deployMYSQL.bicep' = {
  name: 'DeployMYSQLDatabase'
  params: {
    location: location
    dbLoginPwd: dbLoginPwd
  }
  dependsOn: [
    DeployVNET
  ]
}


@description('Docker Password for Asphyticz Account')
@secure()
param dockerRegistryPassword string 

@description('Registry URL To Pull From')
param dockerRegistryUrl string

@description('Registry Login Username')
param dockerRegistryUsername string 

@description('Image to Pull From Repository')
param imageToPull string 
var linuxFxVersion  = 'DOCKER|${imageToPull}'

//Deploys the AppService by referencing the local bicep file
module DeployAppService '03-AppServiceCreation/AppService.bicep' = {
  name: 'DeployAppService'
  params: {
    location: location
    dockerRegistryUrl: dockerRegistryUrl
    dockerRegistryUsername: dockerRegistryUsername
    linuxFxVersion: linuxFxVersion
    dockerRegistryPassword: dockerRegistryPassword
  }
  dependsOn: [
    DeployVNET
    //DeployMYSQLDatabase
  ]
}


//Uncomment if need to use Bastion
@description('JumphostVM UserName')
param jumphostVMUsername string

@description('JumphostVM Password')
@secure()
param jumphostVMPassword string 

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

