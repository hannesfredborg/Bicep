@description('The SQL server name')
param serverName string

@description('The Azure region into wich the resources should be deployed')
param location string = resourceGroup().location

@description('The administrator login username for the SQL server')
param administratorLogin string

@secure()
@description('The administrator login password for the SQL server')
param administratorPassword string

@description('The Key Vault name')
param keyVaultName string

@description('The tenant Id')
param tenantId string

param objectId string

param secret array = [
  'all'
  'backup'
  'delete'
  'get'
  'list'
  'purge'
  'recover'
  'restore'
  'set'
]

@allowed([
  'new'
  'existing'
])

@description('Create new or use existing keyvault')
param newOrExisting string = 'new'

param databaseConfigurations array = []
param fwRules array = []
param sqlDbName array = []
param sqlDbId array = []


resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
  }
}

resource sqlFirewall 'Microsoft.Sql/servers/firewallRules@2021-11-01' = [for (rules, i) in fwRules: {
  name: 'sqlfwrule${i + 1}'
  parent: sqlServer
    properties: {
      startIpAddress: rules.startIpAddress
      endIpAddress: rules.endIpAddress
    }
}]

resource sqlDb 'Microsoft.Sql/servers/databases@2021-11-01' = [for (db, i) in databaseConfigurations: {
  name: db.name
  parent: sqlServer
  location: location
  sku: {
    name: db.skuName
    tier: contains(db, 'skuTier') ? db.skuTier : null
    size: contains(db, 'skuSize') ? db.skuSize : null
  }
}]

output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output sqlDbName array = [for db in sqlDbName: db.id]
output sqlDbId array = [for db in sqlDbId: db.name]

resource PowerShellScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'password-generate'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '5.1' 
    retentionInterval: 'P1D'
    scriptContent: loadTextContent('./generatepwd.ps1')
  }
}

output encoded string =  PowerShellScript.properties.outputs.encodedPassword
output plain string =  PowerShellScript.properties.outputs.password

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' =  if (newOrExisting == 'new') {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: [
      {
        objectId: objectId 
        permissions: {
          secrets: secret
        }
        tenantId: tenantId
      }
    ]
    sku:{
      family: 'A'
      name: 'standard'
      }
      tenantId: tenantId
    }
  }

resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  name: 'password'
  parent: keyVault
  properties: {
    value: PowerShellScript.properties.outputs.password
  }
}
