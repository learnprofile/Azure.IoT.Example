// --------------------------------------------------------------------------------
// This BICEP file will create a Azure Function
// To create the ARM template, run this command:
//   az bicep build --file functionapp.bicep --outfile functionapp.json
// --------------------------------------------------------------------------------

param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param regionName string = resourceGroup().location
param runDateTime string = utcNow()
param templateFile string = '~functionapp.bicep'
param sku string = 'F1'

param functionName string = 'process'
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_RAGRS'])
param storageAccountType string = 'Standard_LRS'
param appInsightsLocation string = resourceGroup().location

// --------------------------------------------------------------------------------
var functionAppName = toLower('${orgPrefix}${appPrefix}${functionName}${environmentCode}${appSuffix}')
var storageAccountName = toLower('${orgPrefix}${appPrefix}${functionName}${environmentCode}${appSuffix}store')
var appServicePlanName = toLower('${functionAppName}plan')
var applicationInsightsName = toLower('${functionAppName}apin')
var keyVaultName = '${orgPrefix}${appPrefix}keyvault${environmentCode}${appSuffix}'

// --------------------------------------------------------------------------------
// var iotHubName = '${orgPrefix}${appPrefix}hub${environmentCode}${appSuffix}'
// resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
// var iotHubConnectionString = 'HostName=${iotHubResource.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iotHubResource.id, iotHubResource.apiVersion).value[0].primaryKey}'

var iotHubKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotHubConnectionString)'
var signalRKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=signalRConnectionString)'
var serviceBusKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=serviceBusConnectionString)'
var cosmosKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=cosmosConnectionString)'
var iotStorageKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotStorageAccountConnectionString)'

// --------------------------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
    SKU: sku
  }
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource functionAppService 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
  }
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
  }
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: functionAppService.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'MySecrets:IoTHubConnectionString'
          value: iotHubKeyVaultReference
        }
        {
          name: 'MySecrets:SignalRConnectionString'
          value: signalRKeyVaultReference
        }
        {
          name: 'MySecrets:ServiceBusConnectionString'
          value: serviceBusKeyVaultReference
        }
        {
          name: 'MySecrets:CosmosConnectionString'
          value: cosmosKeyVaultReference
        }
        {
          name: 'MySecrets:IotStorageAccountConnectionString'
          value: iotStorageKeyVaultReference
        }
        {
          name: 'MyConfiguration:WriteToCosmosYN'
          value: 'Y'
        }
        {
          name: 'MyConfiguration:WriteToSignalRYN'
          value: 'N'
        }
        {
          name: 'ServiceBusConnectionString'
          value: serviceBusKeyVaultReference
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: appInsightsLocation
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}
