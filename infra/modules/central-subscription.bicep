targetScope = 'subscription'

param resourceGroupName string
param location string
param logicAppName string
param office365ConnectionName string
param notificationEmailAddresses string
param ccEmailAddresses string
param emailSubjectPrefix string
param managementGroupId string
param resourceChangeLookbackHours int
param deduplicationRetentionDays int
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module centralResources 'central-resource-group.bicep' = {
  name: 'resources-${uniqueString(subscription().id, resourceGroupName)}'
  scope: resourceGroup
  params: {
    location: location
    logicAppName: logicAppName
    office365ConnectionName: office365ConnectionName
    notificationEmailAddresses: notificationEmailAddresses
    ccEmailAddresses: ccEmailAddresses
    emailSubjectPrefix: emailSubjectPrefix
    managementGroupId: managementGroupId
    resourceChangeLookbackHours: resourceChangeLookbackHours
    deduplicationRetentionDays: deduplicationRetentionDays
    tags: tags
  }
}

output resourceGroupId string = resourceGroup.id
output logicAppResourceId string = centralResources.outputs.logicAppResourceId
output logicAppPrincipalId string = centralResources.outputs.logicAppPrincipalId
output office365ConnectionResourceId string = centralResources.outputs.office365ConnectionResourceId
