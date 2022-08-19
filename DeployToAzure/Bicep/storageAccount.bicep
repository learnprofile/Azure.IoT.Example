﻿// --------------------------------------------------------------------------------
// This BICEP file will create storage account
// --------------------------------------------------------------------------------
param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param location string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~storageAccount.bicep'

@allowed([ 'Standard_LRS', 'Standard_GRS', 'Standard_RAGRS' ])
param storageSku string = 'Standard_LRS'

// --------------------------------------------------------------------------------
var functionStorageName = toLower('${orgPrefix}${appPrefix}func${environmentCode}${appSuffix}store')

// --------------------------------------------------------------------------------
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
    name: functionStorageName
    location: location
    sku: {
        name: storageSku
    }
    tags: {
        LastDeployed: runDateTime
        TemplateFile: templateFileName
        SKU: storageSku
      }
    kind: 'Storage'
    properties: {
        networkAcls: {
            bypass: 'AzureServices'
            virtualNetworkRules: [                
            ]
            ipRules: [                
            ]
            defaultAction: 'Allow'
        }
        supportsHttpsTrafficOnly: true
        encryption: {
            services: {
                file: {
                    keyType: 'Account'
                    enabled: true
                }
                blob: {
                    keyType: 'Account'
                    enabled: true
                }
            }
            keySource: 'Microsoft.Storage'
        }
    }
}

resource blobServiceResource 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
    name: '${storageAccountResource.name}/default'
    properties: {
        cors: {
            corsRules: [                
            ]
        }
        deleteRetentionPolicy: {
            enabled: true
            days: 7
        }
    }
}

output functionStorageAccountName string = storageAccountResource.name
