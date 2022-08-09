// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Function for the IoT Demo Project
// TODO: can I split the unique configuration keys out into a separate file to make this more generic?
// ----------------------------------------------------------------------------------------------------
param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed([ 'dev', 'qa', 'stg', 'prod' ])
param environmentCode string = 'dev'
param appSuffix string = '1'
param location string = resourceGroup().location
param appInsightsLocation string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~functionApp.bicep'

param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'

@allowed([ 'Standard_LRS', 'Standard_GRS', 'Standard_RAGRS' ])
param storageAccountType string = 'Standard_LRS'

// --------------------------------------------------------------------------------
var functionName = 'process'
var functionAppName = toLower('${orgPrefix}-${appPrefix}-${functionName}-${environmentCode}${appSuffix}')
var appServicePlanName = toLower('${functionAppName}-appsvc')
var functionInsightsName = toLower('${functionAppName}-insights')
var functionStorageAccountName = toLower('${orgPrefix}${appPrefix}funcstore${environmentCode}${appSuffix}')
var keyVaultName = '${orgPrefix}${appPrefix}vault${environmentCode}${appSuffix}'

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
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: functionStorageAccountName
  location: location
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
    SKU: functionAppSku
  }
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}
var functionStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'

resource appInsightsResource 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: functionInsightsName
  location: appInsightsLocation
  kind: 'web'
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
  }
  properties: {
    Application_Type: 'web'
    //RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appServiceResource 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'functionapp'
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
    SKU: functionAppSku
  }
  sku: {
    name: functionAppSku
    tier: functionAppSkuTier
    size: functionAppSku
    family: functionAppSkuFamily
    capacity: 0
  }
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

resource functionAppResource 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  //kind: 'functionapp'
  kind: 'functionapp,linux'
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
    SKU: functionAppSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${functionAppName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${functionAppName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServiceResource.id
    reserved: false
    isXenon: false
    hyperV: false
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: functionStorageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: functionStorageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsResource.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
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

// resource functionAppConfig 'Microsoft.Web/sites/config@2018-11-01' = {
//   name: '${functionAppResource.name}/web'
//   properties: {
//     numberOfWorkers: -1
//     defaultDocuments: [
//       'Default.htm'
//       'Default.html'
//       'Default.asp'
//       'index.htm'
//       'index.html'
//       'iisstart.htm'
//       'default.aspx'
//       'index.php'
//       'hostingstart.html'
//     ]
//     netFrameworkVersion: 'v4.0'
//     linuxFxVersion: 'dotnet|3.1'
//     requestTracingEnabled: false
//     remoteDebuggingEnabled: false
//     httpLoggingEnabled: false
//     logsDirectorySizeLimit: 35
//     detailedErrorLoggingEnabled: false
//     publishingUsername: '$${functionAppName}'
//     azureStorageAccounts: {
//     }
//     scmType: 'None'
//     use32BitWorkerProcess: false
//     webSocketsEnabled: false
//     alwaysOn: false
//     managedPipelineMode: 'Integrated'
//     virtualApplications: [
//       {
//         virtualPath: '/'
//         physicalPath: 'site\\wwwroot'
//         preloadEnabled: true
//       }
//     ]
//     loadBalancing: 'LeastRequests'
//     experiments: {
//       rampUpRules: [
//       ]
//     }
//     autoHealEnabled: false
//     cors: {
//       allowedOrigins: [
//         'https://functions.azure.com'
//         'https://functions-staging.azure.com'
//         'https://functions-next.azure.com'
//       ]
//       supportCredentials: false
//     }
//     localMySqlEnabled: false
//     ipSecuriyRestrictions: [
//       {
//         ipAddress: 'Any'
//         action: 'Allow'
//         priority: 1
//         name: 'Allow all'
//         description: 'Wide open to the world :)'
//       }
//     ]
//     scmIpSecurityRestrictions: [
//       {
//         ipAddress: 'Any'
//         action: 'Allow'
//         priority: 1
//         name: 'Allow all'
//         description: 'Wide open to the world :)'
//       }
//     ]
//     scmIpSecurityRestrictionsUseMain: false
//     http20Enabled: true
//     minTlsVersion: '1.2'
//     ftpsState: 'AllAllowed'
//     reservedInstanceCount: 0
//   }
// }

// resource functionAppBinding 'Microsoft.Web/sites/hostNameBindings@2018-11-01' = {
//   name: '${functionAppResource.name}/${functionAppResource.name}.azurewebsites.net'
//   properties: {
//     siteName: functionAppName
//     hostNameType: 'Verified'
//   }
// }

output functionAppPrincipalId string = functionAppResource.identity.principalId
output functionAppName string = functionAppName
output functionInsightsName string = functionInsightsName
output functionInsightsKey string = appInsightsResource.properties.InstrumentationKey
output functionStorageAccountName string = functionStorageAccountName
