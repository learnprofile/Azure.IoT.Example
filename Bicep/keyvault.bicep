// --------------------------------------------------------------------------------
// This BICEP file will create a KeyVault
// To create the ARM template, run this command:
//   az bicep build --file keyvault.bicep --outfile keyvault.json
// --------------------------------------------------------------------------------

param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param regionName string = resourceGroup().location
param runDateTime string = utcNow()
param templateFile string = '~keyvault.bicep'
param sku string = 'F1'

// --------------------------------------------------------------------------------
var keyVaultName = '${orgPrefix}${appPrefix}keyvault${environmentCode}${appSuffix}'

// --------------------------------------------------------------------------------
var iotHubName = '${orgPrefix}${appPrefix}hub${environmentCode}${appSuffix}'
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
var iotHubConnectionString = 'HostName=${iotHubResource.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iotHubResource.id, iotHubResource.apiVersion).value[0].primaryKey}'

var functionName = 'process'
var functionAppName = toLower('${orgPrefix}${appPrefix}${functionName}${environmentCode}${appSuffix}')

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = { name: functionAppName }
var functionAppId = functionApp.identity.principalId

var functionInsightsName = toLower('${functionAppName}apin')
resource functionInsightsResource 'Microsoft.Insights/components@2020-02-02' existing = { name: functionInsightsName }
var functionInsightsKey =functionInsightsResource.properties.InstrumentationKey
// var functionInsightsKey = '${listKeys(functionInsightsResource.id, functionInsightsResource.apiVersion).value[0].InstrumentationKey}'

var webAppName = 'dashboard'
var webSiteName = toLower('${orgPrefix}${appPrefix}${webAppName}${environmentCode}${appSuffix}')

resource webSite 'Microsoft.Web/sites@2021-03-01' existing = { name: webSiteName }
var webSiteAppId = webSite.identity.principalId

var webSiteInsightsName = toLower('${functionAppName}apin')
resource webSiteInsightsResource 'Microsoft.Insights/components@2020-02-02' existing = { name: webSiteInsightsName }
var webSiteInsightsKey =webSiteInsightsResource.properties.InstrumentationKey
// var webSiteInsightsKey = '${listKeys(webSiteInsightsResource.id, webSiteInsightsResource.apiVersion).value[0].InstrumentationKey}'

var iotStorageAccountName = '${orgPrefix}${appPrefix}hub${environmentCode}${appSuffix}store'
resource iotStorageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: iotStorageAccountName }
var iotStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${iotStorageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(iotStorageAccountResource.id, iotStorageAccountResource.apiVersion).keys[0].value}'

var signalRName = '${orgPrefix}${appPrefix}signal${environmentCode}${appSuffix}'
resource signalRResource 'Microsoft.SignalRService/SignalR@2022-02-01' existing = { name: signalRName }
var signalRKey = '${listKeys(signalRResource.id, signalRResource.apiVersion).primaryKey}'
var signalRConnectionString = 'Endpoint=https://${signalRName}.service.signalr.net;AccessKey=${signalRKey};Version=1.0;'

var cosmosName = '${orgPrefix}${appPrefix}cosmos${environmentCode}${appSuffix}'
resource cosmosResource 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' existing = { name: cosmosName }
var cosmosKey = '${listKeys(cosmosResource.id, cosmosResource.apiVersion).primaryMasterKey}'
var cosmosConnectionString = 'AccountEndpoint=https://${cosmosName}.documents.azure.com:443/;AccountKey=${cosmosKey}'

var serviceBusName = '${orgPrefix}${appPrefix}svcbus${environmentCode}${appSuffix}'
resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: serviceBusName }
var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
var serviceBusConnectionString = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 

var ownerUserObjectId = 'fa416629-2180-4614-88ae-cbd7e215378c'

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
    SKU: sku
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId

    // Use Access Policies model
    enableRbacAuthorization: false      
    // add function app and web app identities in the access policies so they can read the secrets
    accessPolicies: [
 
      {
        tenantId: subscription().tenantId
        objectId:  ownerUserObjectId
        permissions: {
          secrets: ['All']
          certificates: ['All']
          keys: ['All']
        } 
      }
 
      {
        objectId:  functionAppId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [ 'get' ]
          certificates: [ 'get' ]
          keys: [ 'get' ]
        }
      }
      {
        objectId:  webSiteAppId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [ 'get' ]
          certificates: [ 'get' ]
          keys: [ 'get' ]
        }
      }
    ]

    enabledForDeployment: true          // VMs can retrieve certificates
    enabledForTemplateDeployment: true  // ARM can retrieve values
    enablePurgeProtection: true         // Not allowing to purge key vault or its objects after deletion
    enableSoftDelete: false
    createMode: 'default'               // Creating or updating the key vault (not recovering)
  }

  resource iotHubSecret 'secrets' = {
    name: 'iotHubConnectionString'
    properties: {
      value: iotHubConnectionString
    }
  }
  resource iotStorageSecret 'secrets' = {
    name: 'iotStorageAccountConnectionString'
    properties: {
      value: iotStorageAccountConnectionString
    }
  }
  resource signalRSecret 'secrets' = {
    name: 'signalRConnectionString'
    properties: {
      value: signalRConnectionString
    }
  }
  resource cosmosSecret 'secrets' = {
    name: 'cosmosConnectionString'
    properties: {
      value: cosmosConnectionString
    }
  }
  resource serviceBusSecret 'secrets' = {
    name: 'serviceBusConnectionString'
    properties: {
      value: serviceBusConnectionString
    }
  }
  resource functionInsightsSecret 'secrets' = {
    name: 'functionInsightsKey'
    properties: {
      value: functionInsightsKey
    }
  }
  resource webSiteInsightsSecret 'secrets' = {
    name: 'webSiteInsightsKey'
    properties: {
      value: webSiteInsightsKey
    }
  }  
}
