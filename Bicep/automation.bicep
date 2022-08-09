// --------------------------------------------------------------------------------
// NOTE: this is a good idea, but it's not working yet....! Deploy fails... :(
// See also: stackoverflow.com/questions/70119888/bicep-template-for-azure-automation-account-azure-role-assignment-to-managed-id
// --------------------------------------------------------------------------------
// This BICEP file will (eventually!) create a Azure Automation Account
// To create the ARM template, run this command:
//   az bicep build --file automation.bicep --outfile automation.json
// --------------------------------------------------------------------------------

param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param regionName string = resourceGroup().location
param runDateTime string = utcNow()
param templateFile string = '~automation.bicep'
param sku string = 'F1'

// --------------------------------------------------------------------------------
var automationName = '${orgPrefix}${appPrefix}auto${environmentCode}${appSuffix}'
// --------------------------------------------------------------------------------

resource automationResource 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: automationName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
    SKU: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: true
    disableLocalAuth: false
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {
      }
    }
  }
}

resource automationAccountResource 'Microsoft.Automation/automationAccounts/connectionTypes@2020-01-13-preview' = {
  parent: automationResource
  name: 'Azure'
  properties: {
    isGlobal: false
    fieldDefinitions: {
      AutomationCertificateName: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      SubscriptionID: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
    }
  }
}

resource automationAccountResourceClassicCertificate 'Microsoft.Automation/automationAccounts/connectionTypes@2020-01-13-preview' = {
  parent: automationResource
  name: 'AzureClassicCertificate'
  properties: {
    isGlobal: false
    fieldDefinitions: {
      SubscriptionName: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      SubscriptionId: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      CertificateAssetName: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
    }
  }
}

resource automationAccountResourceServicePrincipal 'Microsoft.Automation/automationAccounts/connectionTypes@2020-01-13-preview' = {
  parent: automationResource
  name: 'AzureServicePrincipal'
  properties: {
    isGlobal: false
    fieldDefinitions: {
      ApplicationId: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      TenantId: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      CertificateThumbprint: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
      SubscriptionId: {
        isEncrypted: false
        isOptional: false
        type: 'System.String'
      }
    }
  }
}

// resource automationResourceAuditPolicy 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'AuditPolicyDsc'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationResourceModules 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationResourceModuleAccounts 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Accounts'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationResourceModuleAdvisor 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Advisor'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Aks 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Aks'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_AnalysisServices 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.AnalysisServices'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_ApiManagement 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.ApiManagement'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_AppConfiguration 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.AppConfiguration'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_ApplicationInsights 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.ApplicationInsights'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Attestation 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Attestation'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Automation 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Automation'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Batch 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Batch'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Billing 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Billing'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Cdn 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Cdn'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_CloudService 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.CloudService'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_CognitiveServices 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.CognitiveServices'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Compute 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Compute'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_ContainerInstance 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.ContainerInstance'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_ContainerRegistry 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.ContainerRegistry'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_CosmosDB 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.CosmosDB'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_DataBoxEdge 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.DataBoxEdge'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Databricks 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Databricks'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_DataFactory 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.DataFactory'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_DataLakeAnalytics 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.DataLakeAnalytics'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_DataLakeStore 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.DataLakeStore'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_DataShare 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.DataShare'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_DeploymentManager 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.DeploymentManager'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_DesktopVirtualization 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.DesktopVirtualization'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_DevTestLabs 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.DevTestLabs'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Dns 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Dns'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_EventGrid 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.EventGrid'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_EventHub 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.EventHub'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_FrontDoor 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.FrontDoor'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Functions 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Functions'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_HDInsight 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.HDInsight'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_HealthcareApis 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.HealthcareApis'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_IotHub 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.IotHub'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_KeyVault 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.KeyVault'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Kusto 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Kusto'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_LogicApp 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.LogicApp'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_MachineLearning 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.MachineLearning'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Maintenance 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Maintenance'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_ManagedServices 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.ManagedServices'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_MarketplaceOrdering 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.MarketplaceOrdering'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Media 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Media'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Migrate 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Migrate'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Monitor 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Monitor'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_MySql 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.MySql'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Network 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Network'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_NotificationHubs 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.NotificationHubs'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_OperationalInsights 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.OperationalInsights'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_PolicyInsights 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.PolicyInsights'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_PostgreSql 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.PostgreSql'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_PowerBIEmbedded 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.PowerBIEmbedded'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_PrivateDns 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.PrivateDns'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_RecoveryServices 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.RecoveryServices'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_RedisCache 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.RedisCache'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_RedisEnterpriseCache 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.RedisEnterpriseCache'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Relay 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Relay'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_ResourceMover 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.ResourceMover'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Resources 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Resources'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Security 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Security'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_SecurityInsights 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.SecurityInsights'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_ServiceBus 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.ServiceBus'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_ServiceFabric 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.ServiceFabric'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_SignalR 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.SignalR'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Sql 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Sql'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_SqlVirtualMachine 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.SqlVirtualMachine'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_StackHCI 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.StackHCI'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Storage 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Storage'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_StorageSync 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.StorageSync'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_StreamAnalytics 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.StreamAnalytics'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Support 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Support'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Synapse 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Synapse'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_TrafficManager 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.TrafficManager'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationModule_Websites 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Az.Websites'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource Microsoft_Automation_automationAccounts_modules_automationAccountResource 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Azure'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationAccountResource_Storage 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Azure.Storage'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationAccountResourceRM_Automation 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'AzureRM.Automation'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationAccountResourceRM_Compute 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'AzureRM.Compute'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationAccountResourceRM_Profile 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'AzureRM.Profile'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationAccountResourceRM_Resources 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'AzureRM.Resources'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationAccountResourceRM_Sql 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'AzureRM.Sql'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationAccountResourceRM_Storage 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'AzureRM.Storage'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_ComputerManagementDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'ComputerManagementDsc'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_GPRegistryPolicyParser 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'GPRegistryPolicyParser'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_Microsoft_PowerShell_Core 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Microsoft.PowerShell.Core'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_Microsoft_PowerShell_Diagnostics 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Microsoft.PowerShell.Diagnostics'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_Microsoft_PowerShell_Management 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Microsoft.PowerShell.Management'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_Microsoft_PowerShell_Security 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Microsoft.PowerShell.Security'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_Microsoft_PowerShell_Utility 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Microsoft.PowerShell.Utility'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_Microsoft_WSMan_Management 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Microsoft.WSMan.Management'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_Orchestrator_AssetManagement_Cmdlets 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'Orchestrator.AssetManagement.Cmdlets'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_PSDscResources 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'PSDscResources'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_SecurityPolicyDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'SecurityPolicyDsc'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_StateConfigCompositeResources 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'StateConfigCompositeResources'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_xDSCDomainjoin 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'xDSCDomainjoin'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_xPowerShellExecutionPolicy 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'xPowerShellExecutionPolicy'
//   properties: {
//     contentLink: {
//     }
//   }
// }

// resource automationName_xRemoteDesktopAdmin 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
//   parent: automationResource
//   name: 'xRemoteDesktopAdmin'
//   properties: {
//     contentLink: {
//     }
//   }
// }

resource automationAccountResourceAutomationTutorialWithIdentity 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationResource
  name: 'AzureAutomationTutorialWithIdentity'
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
  }
  properties: {
    runbookType: 'PowerShell'
    logVerbose: false
    logProgress: false
    logActivityTrace: 0
  }
}

resource automationAccountResourceAutomationTutorialWithIdentityGraphical 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationResource
  name: 'AzureAutomationTutorialWithIdentityGraphical'
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFile
  }
  properties: {
    runbookType: 'GraphPowerShell'
    logVerbose: false
    logProgress: false
    logActivityTrace: 0
  }
}
