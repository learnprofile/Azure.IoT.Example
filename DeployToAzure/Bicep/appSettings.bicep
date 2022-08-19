// --------------------------------------------------------------------------------
// This BICEP file will add unique Configuration settings to a web or function app
// --------------------------------------------------------------------------------
param appName string
param customAppSettings object

var appSettingsName = '${appName}/appsettings'

resource appResource 'Microsoft.Web/sites@2021-03-01' existing = { name: appName }
var currentAppSettings = list('${appResource.id}/config/appsettings', appResource.apiVersion).properties

resource siteConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  name: appSettingsName
  properties: union(currentAppSettings, customAppSettings)
}
