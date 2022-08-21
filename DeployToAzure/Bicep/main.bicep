// --------------------------------------------------------------------------------
// Main file that deploys all Azure Resources for one environment
// TODO: Bug - fails if resource group doesn't exist...  need to put that in here!
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n main-deploy-20220819T164900Z --resource-group rg_iotdemo_dev --template-file 'main.bicep' --parameters environmentCode=dev orgPrefix=lll appPrefix=iotdemo keyVaultOwnerUserId1=d4aaf634-e777-4307-bb6e-7bf2305d166e keyVaultOwnerUserId2=209019b5-167b-45cd-ab9c-f987fa262040
//   az deployment group create -n main-deploy-20220819T164900Z --resource-group rg_iotdemo_qa --template-file 'main.bicep' --parameters environmentCode=qa orgPrefix=lll appPrefix=iotdemo keyVaultOwnerUserId1=d4aaf634-e777-4307-bb6e-7bf2305d166e keyVaultOwnerUserId2=209019b5-167b-45cd-ab9c-f987fa262040
// --------------------------------------------------------------------------------
param environmentCode string = 'dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = '' // '-1' 
param storageSku string = 'Standard_LRS'
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param webSiteSku string = 'B1'
param keyVaultOwnerUserId1 string = ''
param keyVaultOwnerUserId2 string = ''
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-deploy-${runDateTime}'
var keyVaultName = '${orgPrefix}${appPrefix}vault${environmentCode}${appSuffix}'

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

module storageModule 'storageAccount.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageSku: storageSku

    templateFileName: '~storageAccount.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}
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

var cosmosContainerArray = [
  { name: 'DeviceData', partitionKey: '/partitionKey' }
  { name: 'DeviceInfo', partitionKey: '/partitionKey' }
]
module cosmosModule 'cosmosDatabase.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    containerArray: cosmosContainerArray
    cosmosDatabaseName: 'IoTDatabase'

    templateFileName: '~cosmosDatabase.bicep'
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
  dependsOn: [ storageModule ]
  params: {
    functionName: 'process'
    functionKind: 'functionapp'
    functionAppSku: functionAppSku
    functionAppSkuFamily: functionAppSkuFamily
    functionAppSkuTier: functionAppSkuTier
    functionStorageAccountName: storageModule.outputs.functionStorageAccountName
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

    templateFileName: '~webSite.bicep'
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environmentCode: environmentCode
    appSuffix: appSuffix
    location: location
    runDateTime: runDateTime
  }
}

var adminUserIds = [ keyVaultOwnerUserId1, keyVaultOwnerUserId2 ]
var applicationUserIds = [ functionModule.outputs.functionAppPrincipalId, webSiteModule.outputs.websiteAppPrincipalId ]
module keyVaultModule 'keyVault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ functionModule, webSiteModule ]
  params: {
    adminUserObjectIds: adminUserIds
    applicationUserObjectIds: applicationUserIds
    keyVaultName: keyVaultName

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
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultName
    cosmosAccountName: cosmosModule.outputs.cosmosAccountName
    functionInsightsKey: functionModule.outputs.functionInsightsKey
    iotHubName: iotHubModule.outputs.iotHubName
    iotStorageAccountName: iotHubModule.outputs.iotStorageAccountName
    serviceBusName: servicebusModule.outputs.serviceBusName
    signalRName: signalRModule.outputs.signalRName
    webSiteInsightsKey: webSiteModule.outputs.webSiteAppInsightsKey
  }
}

module functionAppSettingsModule './functionAppSettings.bicep' = {
  name: 'functionAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecretsModule ]
  params: {
    functionAppName: functionModule.outputs.functionAppName
    functionStorageAccountName: functionModule.outputs.functionStorageAccountName
    functionInsightsKey: functionModule.outputs.functionInsightsKey
    customAppSettings: {
      ServiceBusConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=serviceBusConnectionString)'
      'MySecrets:IoTHubConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotHubConnectionString)'
      'MySecrets:SignalRConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=signalRConnectionString)'
      'MySecrets:ServiceBusConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=serviceBusConnectionString)'
      'MySecrets:CosmosConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=cosmosConnectionString)'
      'MySecrets:IotStorageAccountConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotStorageAccountConnectionString)'
      'MyConfiguration:WriteToCosmosYN': 'Y'
      'MyConfiguration:WriteToSignalRYN': 'N'
    }
  }
}

module webSiteAppSettingsModule './webSiteAppSettings.bicep' = {
  name: 'webSiteAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecretsModule ]
  params: {
    webAppName: webSiteModule.outputs.webSiteName
    customAppSettings: {
      EnvironmentName: environmentCode
      IoTHubConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotHubConnectionString)'
      StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotStorageAccountConnectionString)'
      CosmosConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=cosmosConnectionString)'
      SignalRConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=signalRConnectionString)'
      ApplicationInsightsKey: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=webSiteInsightsKey)'
    }
  }
}
