// --------------------------------------------------------------------------------
// This BICEP file will create a Azure Function
// To create the ARM template, run this command:
//   az bicep build --file website.bicep --outfile website.json
// --------------------------------------------------------------------------------

param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param regionName string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~website.bicep'
@allowed(['F1','S1','S2','S3'])
param sku string = 'F1'

param webAppName string = 'dashboard'
param appInsightsLocation string = resourceGroup().location

// --------------------------------------------------------------------------------
var linuxFxVersion = 'DOTNETCORE|6.0' // 	The runtime stack of web app
var webSiteName = toLower('${orgPrefix}${appPrefix}${webAppName}${environmentCode}${appSuffix}')
var appServicePlanName = toLower('${webSiteName}plan')
var applicationInsightsName = toLower('${webSiteName}apin')

var keyVaultName = '${orgPrefix}${appPrefix}keyvault${environmentCode}${appSuffix}'
var iotHubKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotHubConnectionString)'
var iotStorageKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=iotStorageAccountConnectionString)'
var cosmosKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=cosmosConnectionString)'
var signalRKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=signalRConnectionString)'
var appInsightsKeyVaultReference = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=webSiteInsightsKey)'

// --------------------------------------------------------------------------------
resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
    SKU: sku
  }
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: regionName
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'EnvironmentName'
          value: 'DEV'
        }
        {
          name: 'IoTHubConnectionString'
          value: iotHubKeyVaultReference
        }
        {
          name: 'StorageConnectionString'
          value: iotStorageKeyVaultReference
        }
        {
          name: 'CosmosConnectionString'
          value: cosmosKeyVaultReference
        }
        {
          name: 'SignalRConnectionString'
          value: signalRKeyVaultReference
        }
        {
          name: 'ApplicationInsightsKey'
          value: appInsightsKeyVaultReference
        }        
      ]
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: appInsightsLocation
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}
