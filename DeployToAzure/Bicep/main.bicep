// --------------------------------------------------------------------------------
// Main file that deploys all Azure Resources for one environment
// TODO: Bug - fails if resource group doesn't exist...  need to put that in here!
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n main-deploy-20220809T170000Z --resource-group rg_iotdemo_dev --template-file 'main.bicep' --parameters environmentCode=dev orgPrefix=xxx appPrefix=iotdemo
//   az deployment group create -n main-deploy-20220809T170000Z --resource-group rg_iotdemo_qa --template-file 'main.bicep' --parameters environmentCode=qa orgPrefix=xxx appPrefix=iotdemo
// --------------------------------------------------------------------------------
param environmentCode string = 'dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = '' // '-1' 
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param webSiteSku string = 'B1'
param keyVaultOwnerUserId1 string
param keyVaultOwnerUserId2 string
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-deploy-${runDateTime}'

// --------------------------------------------------------------------------------
// TODO: I need a way to create a resource group here, but these don't work yet...!
// --------------------------------------------------------------------------------
// module resourceGroupModule 'resourceGroup.bicep' = {
//   name: 'resourceGroup${deploymentSuffix}'
//   params: {
//     templateFileName: '~resourceGroup.bicep'
//     appPrefix: appPrefix
//     environmentCode: environmentCode
//     location: 'eastus'
//     runDateTime: runDateTime
//   }
// }
// module exampleSubModule 'subModule.bicep' = {
//   name: 'deployToSub'
//   scope: subscription()
// }
// output subscriptionOutput object = subscription()
// module exampleModule 'rgModule.bicep' = {
//   name: 'exampleModule'
//   scope: resourceGroup(resourceGroupName)
// }
// output resourceGroupOutput object = resourceGroup()
// resource resourceGroupResource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
//    name: 'rg-iotdemo-dev'
//    location: location
//    targetScope = subscriptionOutput
// }

module servicebusModule 'serviceBus.bicep' = {
  name: 'servicebus${deploymentSuffix}'
  // dependsOn: [ resourceGroupModule ]
  params: {
    queueNames: [ 'iotmsgs', 'filemsgs' ]

    templateFileName: '~serviceBus.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module iotHubModule 'iotHub.bicep' = {
  name: 'iotHub${deploymentSuffix}'
  // dependsOn: [ resourceGroupModule ]
  params: {
    templateFileName: '~iotHub.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module dpsModule 'dps.bicep' = {
  name: 'dps${deploymentSuffix}'
  dependsOn: [ iotHubModule ]
  params: {
    iotHubName: iotHubModule.outputs.iotHubName

    templateFileName: '~dps.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
var cosmosContainerArray = [
  { name: 'DeviceData', partitionKey: '/partitionKey' }
  { name: 'DeviceInfo', partitionKey: '/partitionKey' }
]
module cosmosModule 'cosmosDatabase.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  // dependsOn: [ resourceGroupModule ]
  params: {
    containerArray: cosmosContainerArray

    templateFileName: '~cosmosDatabase.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module signalRModule 'signalR.bicep' = {
  name: 'signalR${deploymentSuffix}'
  // dependsOn: [ resourceGroupModule ]
  params: {
    templateFileName: '~signalR.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module streamingModule 'streaming.bicep' = {
  name: 'streaming${deploymentSuffix}'
  // dependsOn: [ resourceGroupModule ]
  params: {
    iotHubName: iotHubModule.outputs.iotHubName
    svcBusName: servicebusModule.outputs.serviceBusName
    svcBusQueueName: 'iotmsgs'

    templateFileName: '~streaming.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module functionModule 'functionApp.bicep' = {
  name: 'function${deploymentSuffix}'
  // dependsOn: [ resourceGroupModule ]
  params: {
    functionAppSku: functionAppSku
    functionAppSkuFamily: functionAppSkuFamily
    functionAppSkuTier: functionAppSkuTier
    appInsightsLocation: location

    templateFileName: '~functionApp.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module webSiteModule 'webSite.bicep' = {
  name: 'webSite${deploymentSuffix}'
  // dependsOn: [ resourceGroupModule ]
  params: {
    appInsightsLocation: location
    sku: webSiteSku

    templateFileName: '~webSite1.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}

var owner1UserObjectId = keyVaultOwnerUserId1 // Currently pass in the AD Guid
var owner2UserObjectId = keyVaultOwnerUserId2 // Currently pass in the AD Guid
// Future: Create a powershell step to retrieve Owner Object Guids from an email address:
//   > Connect-AzureAD
//   > $owner1UserObjectId = (Get-AzureAdUser -ObjectId 'someuser@microsoft.com').ObjectId

module keyVaultModule 'keyVault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ servicebusModule, iotHubModule, dpsModule, cosmosModule, functionModule, webSiteModule ]
  params: {
    webSiteAppPrincipalId: webSiteModule.outputs.websiteAppPrincipalId
    functionAppPrincipalId: functionModule.outputs.functionAppPrincipalId
    owner1UserObjectId: owner1UserObjectId
    owner2UserObjectId: owner2UserObjectId
    
    templateFileName: '~keyVault.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
module keyVaultSecretsModule 'keyVaultSecrets.bicep' = {
  name: 'keyvaultSecrets${deploymentSuffix}'
  dependsOn: [ keyVaultModule, servicebusModule, iotHubModule, dpsModule, cosmosModule, functionModule, webSiteModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    iotHubName: iotHubModule.outputs.iotHubName
    iotStorageAccountName: iotHubModule.outputs.iotStorageAccountName
    functionInsightsKey: functionModule.outputs.functionInsightsKey
    webSiteInsightsKey: webSiteModule.outputs.webSiteAppInsightsKey
    signalRName: signalRModule.outputs.signalRName
    cosmosAccountName: cosmosModule.outputs.cosmosAccountName
    serviceBusName: servicebusModule.outputs.serviceBusName
  }
}
