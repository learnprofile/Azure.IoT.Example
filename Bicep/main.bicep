// --------------------------------------------------------------------------------
// Main file that deploys all Azure Resources for one environment
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription d1ced742-2c89-420b-a12a-6d9dc6d48c43
//   az deployment group create -n main-deploy-20220805T140000Z --reswebSiteSkuource-group rg_iotdemo_dev --template-file 'main.bicep' --parameters environmentCode=dev orgPrefix=lll appPrefix=iotdemo
//   az deployment group create -n main-deploy-20220805T140000Z --resource-group rg_iotdemo_qa --template-file 'main.bicep' --parameters environmentCode=qa orgPrefix=lll appPrefix=iotdemo
// --------------------------------------------------------------------------------
param environmentCode string = 'dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = '' // '-1' 
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param webSiteSku string = 'F1'
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-deploy-${runDateTime}'

// --------------------------------------------------------------------------------
module servicebusModule 'serviceBus.bicep' = {
  name: 'servicebus${deploymentSuffix}'
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
  // dependsOn: [ storageModule ]
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
// Create a powershell step to put Owner Object Ids into variables:
var owner1UserObjectId = 'd4aaf634-e777-4307-bb6e-7bf2305d166e' // Lyle's AD Guid
var owner2UserObjectId = '209019b5-167b-45cd-ab9c-f987fa262040' // Chris's AD Guid
//   > Connect-AzureAD
//   > $owner1UserObjectId = (Get-AzureAdUser -ObjectId 'lyleluppes@microsoft.com').ObjectId

module keyVaultModule 'keyVault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [servicebusModule, iotHubModule, dpsModule, cosmosModule, functionModule, webSiteModule]
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
  dependsOn: [ keyVaultModule, servicebusModule, iotHubModule, dpsModule, cosmosModule, functionModule, webSiteModule]
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
