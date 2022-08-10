// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secrets specific to this project
// --------------------------------------------------------------------------------
param keyVaultName string

param iotHubName string
param iotStorageAccountName string
param functionInsightsKey string
param webSiteInsightsKey string
param signalRName string
param cosmosAccountName string
param serviceBusName string

// --------------------------------------------------------------------------------
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
var iotHubConnectionString = 'HostName=${iotHubResource.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iotHubResource.id, iotHubResource.apiVersion).value[0].primaryKey}'

resource iotStorageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: iotStorageAccountName }
var iotStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${iotStorageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(iotStorageAccountResource.id, iotStorageAccountResource.apiVersion).keys[0].value}'

resource signalRResource 'Microsoft.SignalRService/SignalR@2022-02-01' existing = { name: signalRName }
var signalRKey = '${listKeys(signalRResource.id, signalRResource.apiVersion).primaryKey}'
var signalRConnectionString = 'Endpoint=https://${signalRName}.service.signalr.net;AccessKey=${signalRKey};Version=1.0;'

resource cosmosResource 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' existing = { name: cosmosAccountName }
var cosmosKey = '${listKeys(cosmosResource.id, cosmosResource.apiVersion).primaryMasterKey}'
var cosmosConnectionString = 'AccountEndpoint=https://${cosmosAccountName}.documents.azure.com:443/;AccountKey=${cosmosKey}'

resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: serviceBusName }
var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
var serviceBusConnectionString = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = { 
  name: keyVaultName
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
