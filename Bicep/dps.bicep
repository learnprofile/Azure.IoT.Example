// --------------------------------------------------------------------------------
// This BICEP file will create a linked IoT Hub and DPS Service
// To create the ARM template, run this command:
//   az bicep build --file dps.bicep --outfile dps.json
// --------------------------------------------------------------------------------
// NOTE: there is no way yet to automate DPS Enrollment Group creation.
//   After DPS is created, you will need to manually create a group based on
//   the certificate that is created.
// --------------------------------------------------------------------------------

param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','qa','stg','prod'])
param environmentCode string = 'dev'
param appSuffix string = '1'
param regionName string = resourceGroup().location
param runDateTime string = utcNow()
param templateFileName string = '~dps.bicep'
@allowed(['F1','S1','S2','S3'])
param sku string = 'S1'

// --------------------------------------------------------------------------------
var dpsName  = '${orgPrefix}${appPrefix}dps${environmentCode}${appSuffix}'
//var certName = '${orgPrefix}-device-root-cert'

var iotHubName = '${orgPrefix}${appPrefix}hub${environmentCode}${appSuffix}'
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
var iotHubConnectionString = 'HostName=${iotHubResource.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iotHubResource.id, iotHubResource.apiVersion).value[0].primaryKey}'

// --------------------------------------------------------------------------------
// create a Device Provisioning Service and link it to the IoT Hub
resource dpsResource 'Microsoft.Devices/provisioningServices@2022-02-05' = {
  name: dpsName
  location: regionName
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
    SKU: sku
  }
  sku: {
    name: sku
    capacity: 1
  }
  properties: {
    state: 'Active'
    provisioningState: 'Succeeded'
    iotHubs: [
      {
        connectionString: iotHubConnectionString
        location: regionName
      }
    ]
    allocationPolicy: 'Hashed'
    enableDataResidency: false
  }
}

// // NOTE: this certificate data is just the base-64 contents of simple self-signed X509 .pem file
// // WARNING: This works find the first time. Since this is auto-magically set to verified, the SECOND
// //          time you run this, it will fail with an ETAG mismatch.
// resource dpsGroupCertificate 'Microsoft.Devices/provisioningServices/certificates@2022-02-05' = {
//   name: certName
//   parent: dpsResource
//   properties: {
//     certificate: 'MIICDjCCAXcCFGr1kIjSec4nj094+PFzeJxB96CxMA0GCSqGSIb3DQEBCwUAMEYxCzAJBgNVBAYTAlVTMQswCQYDVQQIDAJNTjEaMBgGA1UECgwRTHVwcGVzIENvbnN1bHRpbmcxDjAMBgNVBAMMBWxjaWNhMB4XDTIyMDYxNjE4NTA0M1oXDTIzMDYxNjE4NTA0M1owRjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAk1OMRowGAYDVQQKDBFMdXBwZXMgQ29uc3VsdGluZzEOMAwGA1UEAwwFbGNpY2EwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAONFfIBu/uoLfGfxHnnlJtNqeE1gEWyWHFF9bfHDAir3gy9jttNoiZxhwlNkQxgGKai+dVk9VXlYq3S/UgJJEWYrbQhmaJDAoSDzf6g31pyR3J7z3EPx0QVcxwKMZPy91IKizGupuk1S/r3Cbi/BV/p20X71UHzLHGbiLqFui0wbAgMBAAEwDQYJKoZIhvcNAQELBQADgYEA0OHyKqt+Tw7ZjI3RwZ2MI3pRwNHZ7f3XzcfpQFIGX7zWAZItidWiTTHNSBjzVkXFQiPQCsRaY5YFY9jDPLVDytgA1dtmztwgBIBJloIeZuQ4iJYU7dzxvVg++8ybDYnyzckVS9sNKueF1VOA8AExDU+gawmh/pbe9r8+49/4A+Q='
//     isVerified: true
//   }
// }

// NOTE: as of Jan 2021: creating enrollment groups via ARM templates it is not yet available. 
// This is a known and understood request - no committed timeframe for this yet.
// See github.com/MicrosoftDocs/azure-docs/issues/56161
// Need to automate running a script like this...: 
//   az iot dps enrollment-group create -g {resourceGroupName} --dps-name {dps_name} --enrollment-id {enrollment_id} --certificate-path /certificates/{CertificateName}.pem

// See: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep
// resource runPowerShellInline 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'runPowerShellInline'
//   location: regionName
//   kind: 'AzurePowerShell'
//   // identity: {
//   //   type: 'UserAssigned'
//   //   userAssignedIdentities: {
//   //     '/subscriptions/01234567-89AB-CDEF-0123-456789ABCDEF/resourceGroups/myResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID': {}
//   //   }
//   // }
//   properties: {
//     azPowerShellVersion: '6.4' // or azCliVersion: '2.28.0'
//     // forceUpdateTag: '1'
//     // containerSettings: {
//     //   containerGroupName: 'mycustomaci'
//     // }
//     // storageAccountSettings: {
//     //   storageAccountName: 'myStorageAccount'
//     //   storageAccountKey: 'myKey'
//     // }
//     // arguments: '-name \\"John Dole\\"'
//     // environmentVariables: [
//     //   {
//     //     name: 'UserName'
//     //     value: 'jdole'
//     //   }
//     //   {
//     //     name: 'Password'
//     //     secureValue: 'jDolePassword'
//     //   }
//     // ]
//     scriptContent: '''
//       param([string] $name)
//       az iot dps enrollment-group create -g ${Env:resourceGroupName} --dps-name ${Env:dps_name} --enrollment-id ${Env:enrollment_id} --certificate-path /certificates/${Env:CertificateName}.pem
//     '''
//     supportingScriptUris: []
//     timeout: 'PT30M'
//     cleanupPreference: 'OnSuccess'
//     retentionInterval: 'P1D'
//   }
// }
