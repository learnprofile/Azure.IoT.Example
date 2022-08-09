// --------------------------------------------------------------------------------
// This BICEP file will create a Service Bus
// To create the ARM template, run this command:
//   az bicep build --file svcbus.bicep --outfile svcbus.json
// --------------------------------------------------------------------------------

param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param regionName string = resourceGroup().location
param runDateTime string = utcNow()
param templateFile string = '~svcbus.bicep'
param sku string = 'F1'

// --------------------------------------------------------------------------------
var svcBusName = '${orgPrefix}${appPrefix}svcbus${environmentCode}${appSuffix}'

// --------------------------------------------------------------------------------
resource svcBusResource 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: svcBusName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
    SKU: sku
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    disableLocalAuth: false
    zoneRedundant: false
  }
}

resource svcBusRootManageSharedAccessKeyResource 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: svcBusResource
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource svcBusQueue1Resource 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  parent: svcBusResource
  name: 'iotmsgs'
  properties: {
    maxMessageSizeInKilobytes: 256
    lockDuration: 'PT30S'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
    enableExpress: false
  }
}

// resource svcBusQueueRouteKey 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
//   parent: svcBusQueue1Resource
//   name: 'iothubroutesaccesskey'
//   properties: {
//     rights: [
//       'Send'
//     ]
//   }
// }

resource svcBusQueue2Resource 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  parent: svcBusResource
  name: 'filemsgs'
  properties: {
    maxMessageSizeInKilobytes: 256
    lockDuration: 'PT30S'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
    enableExpress: false
  }
}
