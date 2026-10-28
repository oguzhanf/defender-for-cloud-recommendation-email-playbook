targetScope = 'resourceGroup'

param location string
param logicAppName string
param office365ConnectionName string
param notificationEmailAddresses string
param ccEmailAddresses string
param emailSubjectPrefix string
param managementGroupId string
param resourceChangeLookbackHours int
param deduplicationRetentionDays int
param tags object

var stateContainerName = 'recommendation-state'
var storageAccountName = take('stmdc${uniqueString(subscription().id, resourceGroup().id, logicAppName)}', 24)
var office365ManagedApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource stateContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: stateContainerName
  properties: {
    publicAccess: 'None'
  }
}

resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'delete-expired-recommendation-markers'
          enabled: true
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                delete: {
                  daysAfterModificationGreaterThan: deduplicationRetentionDays
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: [
                '${stateContainerName}/'
              ]
            }
          }
        }
      ]
    }
  }
}

resource office365Connection 'Microsoft.Web/connections@2016-06-01' = {
  name: office365ConnectionName
  location: location
  tags: tags
  properties: {
    api: {
      id: office365ManagedApiId
    }
    displayName: office365ConnectionName
    parameterValues: {}
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: union(tags, {
    LogicAppsCategory: 'security'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: loadJsonContent('../../logicapp/workflow.json')
    parameters: {
      '$connections': {
        value: {
          office365: {
            connectionId: office365Connection.id
            connectionName: office365Connection.name
            id: office365ManagedApiId
          }
        }
      }
      notificationEmailAddresses: {
        value: notificationEmailAddresses
      }
      ccEmailAddresses: {
        value: ccEmailAddresses
      }
      emailSubjectPrefix: {
        value: emailSubjectPrefix
      }
      managementGroupId: {
        value: managementGroupId
      }
      resourceChangeLookbackHours: {
        value: resourceChangeLookbackHours
      }
      stateContainerName: {
        value: stateContainerName
      }
      storageAccountName: {
        value: storageAccountName
      }
    }
  }
  dependsOn: [
    stateContainer
  ]
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, logicApp.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    )
  }
}

output logicAppResourceId string = logicApp.id
output logicAppPrincipalId string = logicApp.identity.principalId
output office365ConnectionResourceId string = office365Connection.id
output storageAccountResourceId string = storageAccount.id
