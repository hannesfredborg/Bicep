@description('The SQL server name')
param serverName string

@description('The SQL Database name')
param sqlDBName string

@description('The name/tier/size of the SQL database SKU')
param  sqlDatabaseSku object

@description('The Azure region into wich the resources should be deployed')
param location string 

@description('The administrator login username for the SQL server')
param administratorLogin string

@secure()
@description('The administrator login password for the SQL server')
param administratorPassword string

@description('The SQL firewallrules name')
param sqlfirewallName string

@description('The firewall start/end IP address')
param startIpAddress string
param endIpAddress string 

param sqlDBPrefix string
param sqlFRPrefix string

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
  }
}

param fireRulesConfigurations array = [
  { name: sqlfirewallName, startIpAddress: startIpAddress, endIpAddress: endIpAddress }
  { name: sqlfirewallName, startIpAddress: startIpAddress, endIpAddress: endIpAddress }
]


resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
  }
}


var databaseConfigurations = [  { name: sqlDBName, tier: sqlDatabaseSku, size: sqlDatabaseSku },  { name: sqlDBName, tier: sqlDatabaseSku, size: sqlDatabaseSku  }]

resource sqlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = [for (sqlDatabaseSku, i) in databaseConfigurations: {
  name: '${sqlDBPrefix}${sqlDatabaseSku.name}${i}'
  location: location
  sku: {
    name: 'sqlDatabaseSku.name'
    tier: 'sqlDatabaseSku.tier'
    size: 'sqlDatabaseSku.size'
  }
  dependsOn: [sqlServer]
}]






