// ----------------------------------------------------------------------------------------------------
// EXPERIMENT: See if we can split out appSettings into separate file... ?????
// ----------------------------------------------------------------------------------------------------


// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Function for the IoT Demo Project
// ----------------------------------------------------------------------------------------------------
// TODO: can I split the unique configuration keys out into a separate file to make this more generic?
// ----------------------------------------------------------------------------------------------------
param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed([ 'dev', 'qa', 'stg', 'prod' ])
param environmentCode string = 'dev'
param appSuffix string = '1'
param keyVaultName string
param appInsightsKey string

// --------------------------------------------------------------------------------
var functionName = 'process'
var functionAppName = toLower('${orgPrefix}-${appPrefix}-${functionName}-${environmentCode}${appSuffix}')
var functionStorageAccountName = toLower('${orgPrefix}${appPrefix}stgfun${environmentCode}${appSuffix}')

// --------------------------------------------------------------------------------
var iotHubKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotHubConnectionString)'
var signalRKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=signalRConnectionString)'
var serviceBusKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=serviceBusConnectionString)'
var cosmosKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=cosmosConnectionString)'
var iotStorageKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotStorageAccountConnectionString)'

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: functionStorageAccountName
}
var functionStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'

resource functionAppResource 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}
resource functionAppConfigResource 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: functionAppResource
  properties: {
    appSettings: {
      [
      AzureWebJobsStorage: functionStorageAccountConnectionString
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: functionStorageAccountConnectionString 
      WEBSITE_CONTENTSHARE: toLower(functionAppName) 
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsKey 
      FUNCTIONS_WORKER_RUNTIME: 'dotnet' 
      FUNCTIONS_EXTENSION_VERSION: '~4' 
      IoTHubConnectionString: iotHubKeyVaultReference 
      SignalRConnectionString: signalRKeyVaultReference
      ServiceBusConnectionString: serviceBusKeyVaultReference
      CosmosConnectionString: cosmosKeyVaultReference
      IotStorageAccountConnectionString: iotStorageKeyVaultReference
      WriteToCosmosYN: 'Y'
      WriteToSignalRYN: 'N'
    ]
  }
}
