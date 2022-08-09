// --------------------------------------------------------------------------------
// This BICEP file will create a Azure Function
// To create the ARM template, run this command:
//   az bicep build --file eventGridSubscription.bicep --outfile eventGridSubscription.json
// --------------------------------------------------------------------------------

param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param regionName string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~eventGridSubscription.bicep'
param sku string = ''

// --------------------------------------------------------------------------------
var eventGridTopicName = '${orgPrefix}${appPrefix}uploadtopic${environmentCode}${appSuffix}'
var eventGridSubscriptionName = '${orgPrefix}${appPrefix}uploadsub${environmentCode}${appSuffix}'
var queueName = 'filemsgs'

// --------------------------------------------------------------------------------
var iotStorageAccountName = '${orgPrefix}${appPrefix}hub${environmentCode}${appSuffix}store'
var iotStorageAccountNameSpace = '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/StorageAccounts/${iotStorageAccountName}'

var svcBusName = '${orgPrefix}${appPrefix}svcbus${environmentCode}${appSuffix}'
var svcBusQueueNameSpace = '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ServiceBus/namespaces/${svcBusName}/queues/${queueName}'

// --------------------------------------------------------------------------------
resource eventGridSystemTopicResource 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: eventGridTopicName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
    SKU: sku
  }
  identity: {
    type: 'None'
  }
  properties: {
    source: iotStorageAccountNameSpace
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource systemTopics_fileuploadstopicdev_name_fileuploadsubscriptiondev 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-12-01' = {
  parent: eventGridSystemTopicResource
  name: eventGridSubscriptionName
  properties: {
    destination: {
      properties: {
        resourceId: svcBusQueueNameSpace
      }
      endpointType: 'ServiceBusQueue'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
        'Microsoft.Storage.BlobDeleted'
      ]
      enableAdvancedFilteringOnArrays: true
    }
    labels: []
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}
