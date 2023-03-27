@description('The SQL server name')
param serverName string

@description('The Azure region into wich the resources should be deployed')
param location string = resourceGroup().location

@description('The administrator login username for the SQL server')
param administratorLogin string

@secure()
@description('The administrator login password for the SQL server')
param administratorPassword string

param databaseConfigurations array = []
param fwRules array = []
param sqlDbIdName array = []

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
  }
}

resource sqlFirewall 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = [for (rules, i) in fwRules: {
  name: 'sqlfwrule${i + 1}'
  parent: sqlServer
    properties: {
      startIpAddress: rules.startIpAddress
      endIpAddress: rules.endIpAddress
    }
}]

resource sqlDb 'Microsoft.Sql/servers/databases@2022-05-01-preview' = [for (db, i) in databaseConfigurations: {
  name: db.name
  parent: sqlServer
  location: location
  sku: {
    name: db.skuName
    tier: contains(db, 'skuTier') ? db.skuTier : null
    size: contains(db, 'skuSize') ? db.skuSize : null


  }
}]

output sqlServerIdName string = '${sqlServer.id} - ${sqlServer.name}'

output sqlDdIdName array = [for db in sqlDbIdName: {
  id: db.id
  name:db.name
}]
